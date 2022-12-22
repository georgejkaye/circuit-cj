/**
 * rewrite/local.cj
 *
 * Local rewrites of hypergraphs
 *
 * @author George Kaye
 * @since 0.3
 */

package rewrite

import prelude.map
import graphs.*
import debug.Debug

from std import collection.HashMap
from std import collection.HashSet

var y = 0

func AttemptRewriteRule<V, G>(
    signature : Signature<V, G>,
    e : Edge<V, G>,
    rule : RewriteRule<V, G>,
    f : InterfacedHypergraph<V, G>
) : Option<(HashSet<TraversalElement<V, G>>, HashSet<TraversalElement<V, G>>)>
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    match(rule.Rewrite(e, f)) {
        case None =>
            Debug("Did not rewrite ${e} with ${rule.name}")
            None
        case Some(result) =>
            Debug("Rewrote ${e} with ${rule.name}")
            // signature.WriteDotToFile(f, 2, "rewrite-${y}-${rule.GetName()}")
            // y++
            Some(result)
    }
}

func CheckAppropriateRules<V, G>(
    edge : Edge<V, G>,
    f : InterfacedHypergraph<V, G>,
    signature : Signature<V, G>
) : Option<(HashSet<TraversalElement<V, G>>, HashSet<TraversalElement<V, G>>)>
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    let label = edge.GetLabel()
    let validRules = ArrayList<RewriteRule<V, G>>()
    func AddRule(rule : RewriteRule<V, G>) {
        validRules.append(rule)
    }
    func AddAnyRules() : Unit {
        AddRule(GetStubRule())
    }
    func AddSignalRules() : Unit {
        AddRule(GetForkRule())
    }
    func AddBundleRules() : Unit {
        AddRule(GetBundleRule(signature))
    }
    func AddPrimitiveRules() : Unit {
        AddRule(GetApplyRule(signature))
    }
    func AddJoinRules() : Unit {
        AddRule(GetJoinRule(signature))
    }
    func AddCompositeRules() : Unit {
        AddRule(GetCompositeRule(signature, true))
    }
    AddAnyRules()
    match(label) {
        case VALUE(_) =>
            AddSignalRules()
        case SIGNAL(_) =>
            AddSignalRules()
        case BUNDLER(_, _) =>
            AddBundleRules()
        case JOIN(_) =>
            AddJoinRules()
        case PRIMITIVE(_) =>
            AddPrimitiveRules()
        case ENHANCED_PRIMITIVE(_) =>
            AddCompositeRules()
        case COMPOSITE(_) =>
            AddCompositeRules()
        case _ => ()
    }
    for(rule in validRules) {
        match(AttemptRewriteRule(signature, edge, rule, f)){
            case None => ()
            case Some(result) => return Some(result)
        }
    }
    return None
}

public func RewriteCombinational<V, G>(
    signature : Signature<V, G>,
    f : InterfacedHypergraph<V, G>,
    starting : HashSet<TraversalElement<V, G>>,
    ending : HashSet<TraversalElement<V, G>>
) : Unit
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    println("The starting elements are ${starting}")
    println("The ending elemnents are ${ending}")
    let actionAtEdge = {
        e : Edge<V, G>, data : TraversalData<V, G> =>
            match(CheckAppropriateRules(e, f, signature)) {
                case Some(result) => result
                case None =>
                    let nextElements = HashSet<TraversalElement<V, G>>()
                    let removedElements = HashSet<TraversalElement<V, G>>()
                    for(t in e.GetTargets()) {
                        let te = VERTEX(t.GetVertex())
                        if(!ending.contains(te)) {
                            nextElements.put(te)
                        }
                    }
                    (nextElements, removedElements)
                }
    }
    let actionAtVertex = {
        v : Vertex<V, G>, data : TraversalData<V, G> =>
        let nextElements = HashSet<TraversalElement<V, G>>()
        for(ec in v.GetOutEdges()) {
            let te = EDGE(ec.GetEdge())
            if(!ending.contains(te)){
                nextElements.put(te)
            }
        }
        (nextElements, HashSet<TraversalElement<V, G>>())
    }
    let startingElements = HashSet<TraversalElement<V, G>>()
    for(e in starting) {
        startingElements.put(e)
    }
    Traverse<V, G>(
        startingElements,
        0,
        actionAtVertex,
        actionAtEdge,
        revisit: true
    )
}