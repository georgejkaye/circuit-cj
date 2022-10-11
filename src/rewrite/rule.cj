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

enum EntryPoint {
    | VALUE
    | PRIMITIVE
}

struct RewriteRule<V, G> where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G> {
    public RewriteRule(
        public let name : String,
        public let entryPoint : EntryPoint,
        public let canRewrite : (Edge<V, G>, InterfacedHypergraph<V, G>) -> Bool,
        public let rewrite :  (Edge<V, G>, InterfacedHypergraph<V, G>) -> ArrayList<Edge<V, G>>
    ){}
    public func CanRewrite(e : Edge<V, G>, f : InterfacedHypergraph<V, G>) : Bool {
        let label = e.GetLabel()
        let validLabel = match(this.entryPoint) {
            case VALUE => label.IsValue()
            case PRIMITIVE => label.IsPrimitive()
        }
        validLabel && this.canRewrite(e, f)
    }
    public func Rewrite(e : Edge<V, G>, f : InterfacedHypergraph<V, G>) : ArrayList<Edge<V, G>> {
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
        for(ec in oldTarget.vertex.GetOutEdges()) {
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
                let nexts = ArrayList<Edge<V, G>>()
                let targets = e.GetTargets()
                let v = targets[0].vertex

                func CopyValue() : (Edge<V, G>, Vertex<V, G>) {
                    let newTarget = Vertex<V, G>(v.GetWidth())
                    // Make a new copy of the value
                    let newEdge = Edge(e.GetLabel(), [], [newTarget], None)
                    f.AddEdgeAndVertices(newEdge)
                    (newEdge, newTarget)
                }

                let edges = v.GetOutEdges()
                // For each outgoing tentacle of the vertex
                for(ec in edges) {
                    let (newEdge, newTarget) = CopyValue()
                    // Hook the new edge into the system
                    ec.edge.SetSource(ec.index, newTarget, false)
                    GetUniqueNextEdges(newEdge, nexts)
                }
                for(i in f.GetOutputPositions(v)) {
                    let (newEdge, newTarget) = CopyValue()
                    f.ReplaceOutput(i, newTarget)
                }
                // We don't need the original edge any more
                f.RemoveEdge(e)
                nexts

        }
    )
}

func GetApplyRule<V, G>(signature : Signature<V, G>) : RewriteRule<V, G>
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{ RewriteRule(
    "apply",
    PRIMITIVE,
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
    },
    {
        e : Edge<V, G>, f : InterfacedHypergraph<V, G> =>
            // We know this edge is a primitive
            let prim = e.GetLabel().GetPrimitive()
            let targets = e.GetTargets()
            f.RemoveEdge(e)
            // We also know all the inputs are values
            let es = map({ t : Tentacle<V, G> => t.vertex.GetInEdge() }, e.GetSources())
            let values = Array<V>(
                es.size,
                { i : Int64 => es[i].getOrThrow().edge.GetLabel().GetValue()}
            )
            for(ei in es) {
                f.RemoveEdge(ei.getOrThrow().edge)
            }
            // Compute the result of the operation
            let result = Signal(signature.gateInterpretation(prim)(values))
            // Create the value edge with this result
            let newTarget = Vertex<V, G>(1)
            let resultEdge = Edge(Label<V, G>.SIGNAL(result), Array<Vertex<V, G>>(), [newTarget], None)
            f.AddEdgeAndVertices(resultEdge)
            // Hook up the next edges
            ReplaceTargets(
                targets,
                [newTarget],
                f
            )
            // Return them
            ArrayList<Edge<V, G>>([resultEdge])
    })
}

func GetRules<V, G>(signature : Signature<V, G>) : Array<RewriteRule<V, G>> where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G> {
    [
        GetForkRule<V, G>(),
        GetApplyRule<V, G>(signature)
    ]
}