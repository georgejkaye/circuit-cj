/**
 * rewrite/rule.cj
 *
 * Contains the definition of a rewrite rule
 *
 * @author George Kaye
 * @since 0.3
 */

package rewrite

from std import collection.ArrayList

import components.*
import prelude.*

public enum EntryPoint {
    | VALUE
    | PRIMITIVE
    | NJOIN
    | SUBGRAPH
    | ANY
    | BUNDLE
}

public struct RewriteRule<V, G> where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G> {
    public let name : String
    public let entryPoint : EntryPoint
    public let canRewrite : (Edge<V, G>, InterfacedHypergraph<V, G>) -> Bool
    public let rewrite : (Edge<V, G>, InterfacedHypergraph<V, G>) -> HashSet<Edge<V, G>>
    public init(
        name : String,
        entryPoint : EntryPoint,
        canRewrite : (Edge<V, G>, InterfacedHypergraph<V, G>) -> Bool,
        rewrite :  (Edge<V, G>, InterfacedHypergraph<V, G>) -> HashSet<Edge<V, G>>
    ){
        this.name = name
        this.entryPoint = entryPoint
        this.canRewrite = canRewrite
        this.rewrite = rewrite
    }
    public func CanRewrite(e : Edge<V, G>, f : InterfacedHypergraph<V, G>) : Bool {
        let label = e.GetLabel()
        let validLabel = match(this.entryPoint) {
            case ANY => true
            case VALUE => label.IsValue()
            case PRIMITIVE => label.IsPrimitive()
            case NJOIN => label.IsJoin()
            case SUBGRAPH => label.IsComposite()
            case BUNDLE => label.IsBundler()
        }
        validLabel && this.canRewrite(e, f)
    }
    public func Rewrite(e : Edge<V, G>, f : InterfacedHypergraph<V, G>) : HashSet<Edge<V, G>> {
        this.rewrite(e, f)
    }
}

func ReplaceTargets<V, G>(
    oldTargets : Array<Tentacle<V, G>>,
    newTargets : Array<Vertex<V, G>>,
    f : InterfacedHypergraph<V, G>
) : Unit where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G> {
    AssertArraysSameLength(oldTargets, newTargets)
    for (i in 0..oldTargets.size){
        let oldTarget = oldTargets[i]
        let newTarget = newTargets[i]
        // Replace sources of edges
        let oldTargetEdges = ArrayList<EdgeConnection<V, G>>(oldTarget.vertex.GetOutEdges())
        for(ec in oldTargetEdges) {
            ec.edge.SetSource(ec.index, newTarget, oldTarget.feedback)
        }
        let outputs = f.GetOutputVertices()
        for(j in 0..outputs.size) {
            let iv = outputs[j]
            if(iv.vertex == oldTarget.vertex) {
                f.GetOutputVertices()[j] = InterfaceVertex(newTarget, iv.name)
            }
        }
    }
}
func GetForkRule<V, G>() : RewriteRule<V, G>
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    RewriteRule<V, G>(
        "fork",
        VALUE,
        {
            e : Edge<V, G>, f : InterfacedHypergraph<V, G> =>
            // VALUE or SIGNAL edges can only have one target
            // although it may be of arbitrary width
            let v = e.GetTargets()[0].vertex
            v.GetOutEdges().size + f.GetOutputPositions(v).size > 1
        },
        {
            e : Edge<V, G>, f : InterfacedHypergraph<V, G> =>
                let nextEdges = HashSet<Edge<V, G>>()
                let targets = e.GetTargets()
                let v = targets[0].vertex

                func CopyValue() : (Edge<V, G>, Vertex<V, G>) {
                    let newTarget = Vertex<V, G>(v.GetWidth())
                    // Make a new copy of the value
                    let newEdge = Edge(e.GetLabel(), [], [newTarget], e.GetSubgraph())
                    f.AddEdgeAndVertices(newEdge)
                    (newEdge, newTarget)
                }

                let edges = HashSet<EdgeConnection<V, G>>(v.GetOutEdges())
                // For each outgoing tentacle of the vertex
                for(ec in edges) {
                    let (newEdge, newTarget) = CopyValue()
                    // Hook the new edge into the system
                    ec.edge.SetSource(ec.index, newTarget, false)
                    GetUniqueNextEdges(newEdge, nextEdges)
                }
                for(i in f.GetOutputPositions(v)) {
                    let (newEdge, newTarget) = CopyValue()
                    f.ReplaceOutput(i, newTarget)
                }
                // We don't need the original edge any more
                f.RemoveEdge(e)
                nextEdges

        }
    )
}
func GetApplyPreconditions<V, G>() : (Edge<V, G>, InterfacedHypergraph<V, G>) -> Bool
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    {
        e : Edge<V, G>, f : InterfacedHypergraph<V, G> =>
        let sources = e.GetSources()
        // Check that none of the values are forked
        // If they are, we need to fork them first!
        for (v in sources) {
            if(v.vertex.GetOutEdges().size != 1){
                return false
            }
        }
        // Check that the inputs are all values
        let es = map({ t : Tentacle<V, G> => t.vertex.GetInEdge() }, sources)
        for(eo in es) {
            match(eo){
                case None => return false
                case Some(ec) =>
                    if(!ec.edge.GetLabel().IsValue()) {
                        return false
                    }
            }
        }
        return true
    }
}
func GetApplyRule<V, G>(signature : Signature<V, G>) : RewriteRule<V, G>
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    RewriteRule<V, G>(
        "apply",
        PRIMITIVE,
        GetApplyPreconditions<V, G>(),
        {
            e : Edge<V, G>, f : InterfacedHypergraph<V, G> =>
                // This edge is guaranteed to be a primitive
                let prim = e.GetLabel().GetPrimitive()
                let function = signature.gateInterpretation(prim)
                // Compute the result of the operation
                let args = map(
                    { t : Tentacle<V, G> => t.vertex.GetInEdge().getOrThrow().edge },
                    e.GetSources()
                )
                let values = Array<V>(
                    args.size,
                    { i : Int64 => args[i].GetLabel().GetValue()}
                )
                let result = function(values)
                let nextEdges = ComputeEdge(f, e, args, [result])
                nextEdges
        }
    )
}

func GetStubRule<V, G>(signature : Signature<V, G>) : RewriteRule<V, G>
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    RewriteRule<V, G>(
        "stub",
        ANY,
        {
            e : Edge<V, G>, f : InterfacedHypergraph<V, G> =>
                let targets = e.GetTargets()
                for(t in targets) {
                    let v = t.vertex
                    // We can only discard if there are no outgoing tentacles
                    if(v.GetOutEdges().size != 0 || f.GetOutputPositions(v).size != 0) {
                        return false
                    }
                }
                return true
        },
        {
            e : Edge<V, G>, f : InterfacedHypergraph<V, G> =>
                // We need to add whatever is 'left' of this edge so that we can potentially
                // discard more edges
                let nextEdges = HashSet<Edge<V, G>>()
                for(t in e.GetSources()){
                    let v = t.vertex
                    match(v.GetInEdge()){
                        case Some(ec) => nextEdges.put(ec.edge)
                        case None => ()
                    }
                }
                // We can remove this edge now, but not its sources as these will be used
                // by other edges. Conversely, we have already confirmed that nothing else
                // is using the targets so they can be deleted
                f.RemoveEdge(e, false, true)
                nextEdges
        }
    )
}
func GetJoinRule<V, G>(signature : Signature<V, G>)
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    RewriteRule<V, G>(
        "join",
        NJOIN,
        GetApplyPreconditions<V, G>(),
        {
            e : Edge<V, G>, f : InterfacedHypergraph<V, G> =>
                // This edge is guaranteed to be a join
                // Compute the result of the operation
                let argLHS = e.GetSource(0).vertex.GetInEdge().getOrThrow().edge
                let argRHS = e.GetSource(1).vertex.GetInEdge().getOrThrow().edge
                let result = signature.JoinPowers(argLHS.GetLabel().GetValueArray(), argRHS.GetLabel().GetValueArray())
                let nextEdges = ComputeEdge(f, e, [argLHS, argRHS], [result])
                nextEdges
        }
    )
}
func ArgumentIsAllValue<V, G>(v : V, e : Edge<V, G>, i : Int64) : Bool
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    let label = e.GetSource(i).vertex.GetInEdge().getOrThrow().edge.GetLabel()
    label.IsAllValue(v)
}
func RemoveBinaryArgumentAndPassthrough<V, G>(e : Edge<V, G>, i : Int64, f : InterfacedHypergraph<V, G>) : HashSet<Edge<V, G>>
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    let arg = e.GetSource(i).vertex.GetInEdge().getOrThrow().edge
    let otherIndex = if(i == 0){
        1
    } else {
        0
    }
    let target = e.GetTarget(0).vertex
    let source = e.GetSource(otherIndex).vertex
    f.RemoveEdge(e, false, false)
    f.RemoveEdge(arg)
    MergeVertices(source, target, false)
    HashSet<Edge<V, G>>([source.GetInEdge().getOrThrow().edge])
}

func GetJoinUnitRule<V, G>(signature : Signature<V, G>, i : Int64, str : String)
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
        RewriteRule<V, G>(
        "join-unit-${str}",
        NJOIN,
        {
            e : Edge<V, G>, f : InterfacedHypergraph<V, G> =>
                ArgumentIsAllValue(signature.GetBottom(), e, i)
        },
        {
            e : Edge<V, G>, f : InterfacedHypergraph<V, G> =>
                RemoveBinaryArgumentAndPassthrough(e, i, f)
        }
    )
}
func GetJoinUnitLeftRule<V, G>(signature : Signature<V, G>)
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    GetJoinUnitRule(signature, 0, "l")
}
func GetJoinUnitRightRule<V, G>(signature : Signature<V, G>)
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    GetJoinUnitRule(signature, 1, "r")
}
func ComputeEdge<V, G>(
    f : InterfacedHypergraph<V, G>,
    edge : Edge<V, G>,
    args : Array<Edge<V, G>>,
    result : Array<Array<V>>
) : HashSet<Edge<V, G>>
     where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    let targets = edge.GetTargets()
    f.RemoveEdge(edge)
    // We also know all the inputs are values
    for(e in args) {
        f.RemoveEdge(e)
    }
    let nextEdges = HashSet<Edge<V, G>>()
    // Create the value edge with this result
    for(vs in result) {
        let newTarget = Vertex<V, G>(vs.size)
        let subcircuit = if(vs.size == 1){
            None<InterfacedHypergraph<V, G>>
        } else {
            MakeSignal<V, G>(Signal(vs))
        }
        let label = GetSignalLabel<V, G>(vs)
        let resultEdge = Edge(label, Array<Vertex<V, G>>(), [newTarget], subcircuit)
        f.AddEdgeAndVertices(resultEdge)
        // Hook up the next edges
        ReplaceTargets(
            targets,
            [newTarget],
            f
        )
        nextEdges.put(resultEdge)
    }
    // Return them
    nextEdges
}

func GetCompositeRule<V, G>()
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    RewriteRule<V, G>(
        "composite",
        SUBGRAPH,
        { e : Edge<V, G>, f : InterfacedHypergraph<V, G> => true },
        {
            e : Edge<V, G>, f : InterfacedHypergraph<V, G> =>
                let nextEdges = HashSet<Edge<V, G>>()
                for(t in e.GetSources()) {
                    let v = t.vertex
                    match(v.GetInEdge()) {
                        case None => ()
                        case Some(e) => nextEdges.put(e.edge)
                    }
                }
                e.BurstSubgraph()
                nextEdges
        }
    )
}
func GetBundleRule<V, G>(sig : Signature<V, G>)
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    RewriteRule<V, G>(
        "bundle",
        BUNDLE,
        GetApplyPreconditions<V, G>(),
        {
            e : Edge<V, G>, f : InterfacedHypergraph<V, G> =>
                let values = ArrayList<V>()
                // Get all the individual values in a list
                for(t in e.GetSources()){
                    let v = t.vertex
                    // Precondition enforces there must be an in edge
                    let valueEdge = v.GetInEdge().getOrThrow().edge
                    match(valueEdge.GetLabel()) {
                        case VALUE(v) => values.append(v)
                        case SIGNAL(sig) =>
                            let subgraph = valueEdge.GetSubgraph().getOrThrow()
                            let combineEdge = subgraph.GetOutput(0).vertex.GetInEdge().getOrThrow().edge
                            for(tt in combineEdge.GetSources()) {
                                values.append(tt.vertex.GetInEdge().getOrThrow().edge.GetLabel().GetValue())
                            }
                        case _ => ()
                    }
                    f.RemoveEdge(valueEdge, true, false)
                }
                let newEdges = HashSet<Edge<V, G>>()
                let targets = e.GetTargets()
                f.RemoveEdge(e, true, false)
                for(t in targets) {
                    let v = t.vertex
                    let width = v.GetWidth()
                    let newEdge = if(width == 1) {
                        let value = values.remove(0)
                        Edge(Label.VALUE(value), Array<Tentacle<V, G>>(), [t], None, f.GetGraph())
                    } else {
                        let wireValues = Array<V>(width){
                            i : Int64 => values.remove(0)
                        }
                        let signal = Signal(wireValues)
                        let signalGraph = MakeSignal<V, G>(signal)
                        Edge(SIGNAL(signal), Array<Tentacle<V, G>>(), [t], signalGraph, f.GetGraph())
                    }
                    newEdges.put(newEdge)
                }
                newEdges
        }
    )
}


func GetRules<V, G>(signature : Signature<V, G>, now : Bool) : ArrayList<RewriteRule<V, G>>
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    let rules = ArrayList<RewriteRule<V, G>>()
    rules.append(GetForkRule<V, G>())
    rules.append(GetBundleRule<V, G>(signature))
    rules.append(GetApplyRule<V, G>(signature))
    rules.append(GetStubRule<V, G>(signature))
    rules.append(GetJoinRule<V, G>(signature))
    if(now) {
        rules.append(GetCompositeRule<V, G>())
    } else {
        rules.append(GetJoinUnitLeftRule<V, G>(signature))
        rules.append(GetJoinUnitRightRule<V, G>(signature))
    }
    rules
}
