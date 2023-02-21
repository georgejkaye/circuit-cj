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
import utils.*

public enum EntryPoint {
    | VALUE
    | PRIMITIVE
    | NJOIN
    | ENHANCED
    | SUBGRAPH
    | ANY
    | BUNDLE
}
public struct RewriteRule<V, G> where V <: ValueSymbol & Equatable<V> & LessOrEqual<V>, G <: PrimitiveSymbol<V> & Equatable<G> {
    public let name : String
    public let entryPoint : EntryPoint
    public let rewrite : (Edge<V, G>, InterfacedHypergraph<V, G>)
                            -> Option<(HashSet<TraversalElement<V, G>>, HashSet<TraversalElement<V, G>>)>
    public init(
        name : String,
        entryPoint : EntryPoint,
        rewrite :  (Edge<V, G>, InterfacedHypergraph<V, G>)
                        -> Option<(HashSet<TraversalElement<V, G>>, HashSet<TraversalElement<V, G>>)>
    ){
        this.name = name
        this.entryPoint = entryPoint
        this.rewrite = rewrite
    }
    public func CanRewrite(e : Edge<V, G>, f : InterfacedHypergraph<V, G>) : Bool {
        let label = e.GetLabel()
        match(this.entryPoint) {
            case ANY => true
            case VALUE => label.IsValue()
            case PRIMITIVE => label.IsPrimitive()
            case NJOIN => label.IsJoin()
            case ENHANCED => label.IsEnhanced()
            case SUBGRAPH => label.IsComposite()
            case BUNDLE => label.IsBundler()
        }
    }
    public func GetName() : String {
        this.name
    }
    public func Rewrite(
        e : Edge<V, G>,
        f : InterfacedHypergraph<V, G>
    ) : Option<(HashSet<TraversalElement<V, G>>, HashSet<TraversalElement<V, G>>)> {
        this.rewrite(e, f)
    }
}

func ReplaceTargets<V, G>(
    oldTargets : Array<Tentacle<V, G>>,
    newTargets : Array<Vertex<V, G>>,
    f : InterfacedHypergraph<V, G>
) : Unit where V <: ValueSymbol & Equatable<V> & LessOrEqual<V>, G <: PrimitiveSymbol<V> & Equatable<G> {
    AssertArraysSameLength(oldTargets, newTargets)
    for (i in 0..oldTargets.size){
        let oldTarget = oldTargets[i]
        let newTarget = newTargets[i]
        // Replace sources of edges
        let oldTargetEdges = ArrayList<EdgeConnection<V, G>>(oldTarget.vertex.GetOutEdges())
        for(ec in oldTargetEdges) {
            ec.GetEdge().SetSource(ec.GetIndex(), newTarget, oldTarget.feedback)
        }
        let outputs = f.GetOutputs()
        for(j in 0..outputs.size) {
            let iv = outputs[j]
            if(iv.vertex == oldTarget.vertex) {
                f.GetOutputs()[j] = InterfaceVertex(newTarget, iv.name)
            }
        }
    }
}
func GetForkRule<V, G>() : RewriteRule<V, G>
    where V <: ValueSymbol & Equatable<V> & LessOrEqual<V>, G <: PrimitiveSymbol<V> & Equatable<G>
{
    RewriteRule<V, G>(
        "fork",
        VALUE,
        {
            e : Edge<V, G>, f : InterfacedHypergraph<V, G> =>
                // VALUE or SIGNAL edges can only have one target
                // although it may be of arbitrary width
                let v = e.GetTargets()[0].vertex
                if(!(v.GetOutEdges().size + f.GetOutputPositions(v).size > 1)){
                    None
                } else {
                    let nextEdges = HashSet<TraversalElement<V, G>>()
                    let removedEdges = HashSet<TraversalElement<V, G>>()
                    let target = e.GetTarget(0).GetVertex()
                    let outEdges = HashSet<EdgeConnection<V, G>>(target.GetOutEdges())
                    for(ec in outEdges) {
                        let newTarget = Vertex<V, G>(target.GetWidth())
                        let newEdge = Edge(
                            e.GetLabel(),
                            Array<Vertex<V, G>>(),
                            [newTarget],
                            e.GetSubgraph(),
                            f.GetGraph()
                        )
                        ec.GetEdge().SetSource(ec.GetIndex(), newTarget, false)
                        nextEdges.put(EDGE(newEdge))
                    }
                    f.RemoveEdge(e)
                    removedEdges.put(EDGE(e))
                    f.RemoveVertex(target)
                    removedEdges.put(VERTEX(target))
                    Some((nextEdges, removedEdges))
                }
        }
    )
}
func ApplyPreconditions<V, G>(e : Edge<V, G>, f : InterfacedHypergraph<V, G>) : Bool
    where V <: ValueSymbol & Equatable<V> & LessOrEqual<V>, G <: PrimitiveSymbol<V> & Equatable<G>
{
    let sources = e.GetSources()
    // Check that none of the values are forked
    // If they are, we need to fork them first!
    for (v in sources) {
        if(v.vertex.GetOutEdges().size != 1){
            return false
        }
    }
    // Check arguments are all values
    for(t in sources) {
        let v = t.GetVertex()
        match(v.GetInEdge()){
            case None => return false
            case Some(ec) =>
                if(!ec.GetEdge().GetLabel().IsValue()) {
                    return false
                }
        }
    }
    return true
}
func GetApplyRule<V, G>(signature : Signature<V, G>) : RewriteRule<V, G>
    where
        V <: ValueSymbol & Equatable<V> & LessOrEqual<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
{
    RewriteRule<V, G>(
        "apply",
        PRIMITIVE,
        {
            e : Edge<V, G>, f : InterfacedHypergraph<V, G> =>
                if(!ApplyPreconditions(e, f)){
                    None
                } else {
                    // This edge is guaranteed to be a primitive
                    let prim = e.GetLabel().GetPrimitive()
                    let function = signature.gateInterpretation(prim)
                    // Compute the result of the operation
                    let args = map(
                        { t : Tentacle<V, G> => t.vertex.GetInEdge().getOrThrow().edge },
                        e.GetSources()
                    )
                    let values = Array<Array<V>>(
                        args.size,
                        { i : Int64 => args[i].GetLabel().GetSignal().values}
                    )
                    let result = function(values)
                    ComputeEdge(signature, f, e, args, [result])
                }
        }
    )
}

func GetStubRule<V, G>() : RewriteRule<V, G>
    where V <: ValueSymbol & Equatable<V> & LessOrEqual<V>, G <: PrimitiveSymbol<V> & Equatable<G>
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
                        return None
                    }
                }
                // We need to add whatever is 'left' of this edge so that we can potentially
                // discard more edges
                let nextEdges = HashSet<TraversalElement<V, G>>()
                let removedEdges = HashSet<TraversalElement<V, G>>()
                for(t in e.GetSources()){
                    let v = t.vertex
                    v.RemoveOutEdge(e)
                    match(v.GetInEdge()){
                        case Some(ec) => nextEdges.put(EDGE(ec.GetEdge()))
                        case None =>
                            if(v.GetInterfacedInputs().size == 0){
                                f.RemoveVertex(v)
                                removedEdges.put(VERTEX(v))
                            }
                    }
                }
                // We can remove this edge now, but not its sources as these will be used
                // by other edges. Conversely, we have already confirmed that nothing else
                // is using the targets so they can be deleted
                f.RemoveEdge(e)
                removedEdges.put(EDGE(e))
                for(t in e.GetTargets()) {
                    let v = t.GetVertex()
                    f.RemoveVertex(v)
                    removedEdges.put(VERTEX(v))
                }
                (nextEdges, removedEdges)
        }
    )
}
func GetJoinRule<V, G>(signature : Signature<V, G>)
    where
        V <: ValueSymbol & Equatable<V> & LessOrEqual<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
{
    RewriteRule<V, G>(
        "join",
        NJOIN,
        {
            e : Edge<V, G>, f : InterfacedHypergraph<V, G> =>
                if(!ApplyPreconditions(e, f)){
                    None
                } else {
                    // This edge is guaranteed to be a join
                    // Compute the result of the operation
                    let argLHS = e.GetSource(0).vertex.GetInEdge().getOrThrow().edge
                    let argRHS = e.GetSource(1).vertex.GetInEdge().getOrThrow().edge
                    let result = signature.Join(argLHS.GetLabel().GetValueArray(), argRHS.GetLabel().GetValueArray())
                    Some(ComputeEdge(signature, f, e, [argLHS, argRHS], [result]))
                }
        }
    )
}
func ArgumentIsAllValue<V, G>(v : V, e : Edge<V, G>, i : Int64) : Bool
    where
        V <: ValueSymbol & Equatable<V> & LessOrEqual<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
{
    match(e.GetSource(i).vertex.GetInEdge()){
        case None => false
        case Some(e) => e.GetEdge().GetLabel().IsAllValue(v)
    }
}
func ArgumentsAreAllValue<V, G>(v : V, e : Edge<V, G>) : Bool
    where
        V <: ValueSymbol & Equatable<V> & LessOrEqual<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
{
    if(e.GetArity() > 0) {
        for(i in 0..e.GetArity()) {
            if(!ArgumentIsAllValue(v, e, i)) {
                return false
            }
        }
        true
    } else {
        false
    }
}
func RemoveBinaryArgumentAndPassthrough<V, G>(
    e : Edge<V, G>,
    i : Int64,
    f : InterfacedHypergraph<V, G>
) : (HashSet<TraversalElement<V, G>>, HashSet<TraversalElement<V, G>>)
    where V <: ValueSymbol & Equatable<V> & LessOrEqual<V>, G <: PrimitiveSymbol<V> & Equatable<G>
{
    let arg = e.GetSource(i).vertex.GetInEdge().getOrThrow().edge
    let otherIndex = if(i == 0){
        1
    } else {
        0
    }
    let target = e.GetTarget(0).vertex
    let source = e.GetSource(otherIndex).vertex
    let nextEdges = HashSet<TraversalElement<V, G>>()
    let removedEdges = HashSet<TraversalElement<V, G>>()
    f.RemoveEdge(e)
    removedEdges.put(EDGE(e))
    target.RemoveInEdge()
    // Remove the redundant arguments
    f.RemoveEdge(arg)
    removedEdges.put(EDGE(arg))
    for(t in arg.GetTargets()) {
        let v = t.GetVertex()
        f.RemoveVertex(v)
        removedEdges.put(VERTEX(v))
    }
    MergeVertices(source, target, false)
    nextEdges.put(EDGE(source.GetInEdge().getOrThrow().edge))
    (nextEdges, removedEdges)
}

func GetJoinUnitRule<V, G>(signature : Signature<V, G>, i : Int64, str : String)
    where
        V <: ValueSymbol & Equatable<V> & LessOrEqual<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
{
        RewriteRule<V, G>(
        "join-unit-${str}",
        NJOIN,
        {
            e : Edge<V, G>, f : InterfacedHypergraph<V, G> =>
                if(!ArgumentIsAllValue(signature.GetBottom(), e, i)){
                    None
                } else {
                    Some(RemoveBinaryArgumentAndPassthrough(e, i, f))
                }
        }
    )
}
func GetJoinUnitLeftRule<V, G>(signature : Signature<V, G>)
    where
        V <: ValueSymbol & Equatable<V> & LessOrEqual<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
{
    GetJoinUnitRule(signature, 0, "l")
}
func GetJoinUnitRightRule<V, G>(signature : Signature<V, G>)
    where V <: ValueSymbol & Equatable<V> & LessOrEqual<V> & LessOrEqual<V>,
    G <: PrimitiveSymbol<V> & Equatable<G>
{
    GetJoinUnitRule(signature, 1, "r")
}
func ComputeEdge<V, G>(
    signature : Signature<V, G>,
    f : InterfacedHypergraph<V, G>,
    e : Edge<V, G>,
    args : Array<Edge<V, G>>,
    results : Array<Array<V>>
) : (HashSet<TraversalElement<V, G>>, HashSet<TraversalElement<V, G>>)
     where
        V <: ValueSymbol & Equatable<V> & LessOrEqual<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
{
    let nextEdges = HashSet<TraversalElement<V, G>>()
    let removedEdges = HashSet<TraversalElement<V, G>>()
    let targets = e.GetTargets()
    for(arg in args) {
        f.RemoveEdge(arg)
        removedEdges.put(EDGE(arg))
    }
    for(t in targets){
        let v = t.GetVertex()
        v.RemoveInEdge(e)
    }
    for(t in e.GetSources()) {
        let v = t.GetVertex()
        f.RemoveVertex(v)
        removedEdges.put(VERTEX(v))
    }
    f.RemoveEdge(e)
    removedEdges.put(EDGE(e))
    for(i in 0..results.size) {
        let result = results[i]
        let signal = GetSignalLabel<V, G>(result)
        let signalGraph = signature.MakeSignal(Signal(result))
        let target = e.GetTarget(i).GetVertex()
        target.RemoveInEdge()
        let newEdge = Edge(
            Label<V,G>.SIGNAL(Signal(result)),
            Array<Vertex<V, G>>(),
            [target],
            Some(signalGraph),
            Some(f.GetGraph())
        )
        nextEdges.put(EDGE(newEdge))
    }
    (nextEdges, removedEdges)
}
func GetEnhancedRule<V, G>(signature : Signature<V, G>)
    where
        V <: ValueSymbol & Equatable<V> & LessOrEqual<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
{
        RewriteRule<V, G>(
        "enhanced",
        ENHANCED,
        { e : Edge<V, G>, f : InterfacedHypergraph<V, G> =>
            if(!ApplyPreconditions(e, f)){
                None
            } else {
                Some(ExpandSubgraphRewrite(e, f))
            }
        }
    )
}
func GetCompositeRule<V, G>(signature : Signature<V, G>, all : Bool)
    where
        V <: ValueSymbol & Equatable<V> & LessOrEqual<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
{
    RewriteRule<V, G>(
        "composite",
        SUBGRAPH,
        { e : Edge<V, G>, f : InterfacedHypergraph<V, G> =>
            if(!ApplyPreconditions(e, f)){
                None
            } else {
                Some(ExpandSubgraphRewrite(e, f))
            }
        }
    )
}
func ExpandSubgraphRewrite<V, G>(
    e : Edge<V, G>, f : InterfacedHypergraph<V, G>
) : (HashSet<TraversalElement<V, G>>, HashSet<TraversalElement<V, G>>)
    where
        V <: ValueSymbol & Equatable<V> & LessOrEqual<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
{

    let nextEdges = HashSet<TraversalElement<V, G>>()
    let removedEdges = HashSet<TraversalElement<V, G>>()
    let subgraph = e.GetSubgraph().getOrThrow()
    for(edge in subgraph.GetSequentialData().valueEdges){
        nextEdges.put(EDGE(edge))
    }
    let (newSources, newTargets) = e.BurstSubgraph()
    for(t in newSources) {
        match(t.GetVertex().GetInEdge()){
            case Some(ec) => nextEdges.put(EDGE(ec.GetEdge()))
            case None => ()
        }
    }
    removedEdges.put(EDGE(e))
    (nextEdges, removedEdges)
}
func GetBundleRule<V, G>(sig : Signature<V, G>)
    where
        V <: ValueSymbol & Equatable<V> & LessOrEqual<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
{
    RewriteRule<V, G>(
        "bundle",
        BUNDLE,
        {
            e : Edge<V, G>, f : InterfacedHypergraph<V, G> =>
                if(!ApplyPreconditions(e, f)){
                    None
                } else {
                    let newEdges = HashSet<TraversalElement<V, G>>()
                    let removedEdges = HashSet<TraversalElement<V, G>>()
                    let values = ArrayList<V>()
                    // Get all the individual values in a list
                    for(t in e.GetSources()){
                        let v = t.GetVertex()
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
                        f.RemoveEdge(valueEdge)
                        removedEdges.put(EDGE(valueEdge))
                        f.RemoveVertex(t.GetVertex())
                        removedEdges.put(VERTEX(v))
                    }
                    f.RemoveEdge(e)
                    removedEdges.put(EDGE(e))
                    for(t in e.GetTargets()) {
                        let v = t.GetVertex()
                        v.RemoveInEdge()
                        let width = v.GetWidth()
                        let newEdge = if(width == 1) {
                            let value = values.remove(0)
                            Edge(Label.VALUE(value), Array<Vertex<V, G>>(), [v], None, f.GetGraph())
                        } else {
                            let wireValues = Array<V>(width){
                                i : Int64 => values.remove(0)
                            }
                            let signal = Signal(wireValues)
                            let signalGraph = sig.MakeSignal(signal)
                            Edge(SIGNAL(signal), Array<Vertex<V, G>>(), [v], signalGraph, f.GetGraph())
                        }
                        newEdges.put(EDGE(newEdge))
                    }
                    Some((newEdges, removedEdges))
                }
        }
    )
}
func GetMergeBundlesRule<V, G>(signature : Signature<V, G>)
    where
        V <: ValueSymbol & Equatable<V> & LessOrEqual<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
{
    RewriteRule<V, G>(
        "bundle",
        BUNDLE,
        { e : Edge<V, G>, f : InterfacedHypergraph<V, G> =>
            None
        }
    )
}
func GetRules<V, G>(signature : Signature<V, G>, now : Bool) : ArrayList<RewriteRule<V, G>>
    where
        V <: ValueSymbol & Equatable<V> & LessOrEqual<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
{
    let rules = ArrayList<RewriteRule<V, G>>()
    if(now){
        rules.append(GetForkRule<V, G>())
        rules.append(GetStubRule<V, G>())
        rules.append(GetBundleRule<V, G>(signature))
        rules.append(GetApplyRule<V, G>(signature))
        rules.append(GetJoinRule<V, G>(signature))
        rules.append(GetEnhancedRule<V, G>(signature))
        rules.append(GetCompositeRule<V, G>(signature, true))
        rules.append(GetMergeBundlesRule<V, G>(signature))
    } else {
        // rules.append(GetForkRule<V, G>())
        rules.append(GetStubRule<V, G>())
        rules.append(GetCompositeRule<V, G>(signature, true))
        // rules.append(GetJoinUnitLeftRule<V, G>(signature))
        // rules.append(GetJoinUnitRightRule<V, G>(signature))
    }
    rules
}