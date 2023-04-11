/**
 * rewrite/local.cj
 *
 * Local rewrites of hypergraphs
 *
 * @author George Kaye
 * @since 0.3
 */

package rewrite

from std import collection.HashMap
from std import collection.HashSet

var y = 0

func AttemptRewriteRule<V, G>(
    signature : Signature<V, G>,
    e : Edge<V, G>,
    rule : RewriteRule<V, G>,
    f : InterfacedHypergraph<V, G>
) : Option<HashSet<TraversalElement<V, G>>>
    where
        V <: ValueSymbol<V> & Equatable<V> & LessOrEqual<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
{
    match(rule.Rewrite(e, f)) {
        case None =>
            // Debug("Did not rewrite ${e} with ${rule.name}")
            None
        case Some(result) =>
            Debug("Rewrote ${e} with ${rule.name}")
            f.WriteDotToFile(
                0, "dot/rewrite-${y}-${e.GetId()}-${rule.GetName()}",
                debug: true
            )
            y++
            Some(result)
    }
}
func CheckAppropriateRules<V, G>(
    edge : Edge<V, G>,
    f : InterfacedHypergraph<V, G>,
    signature : Signature<V, G>,
    copyBlackBoxes!: Bool = false,
    allInstantaneous!: Bool = false
) : Option<HashSet<TraversalElement<V, G>>>
    where
        V <: ValueSymbol<V> & Equatable<V> & LessOrEqual<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
{
    let label = edge.GetLabel()
    let validRules = ArrayList<RewriteRule<V, G>>()
    // Hashmap for tracking the 'active' vertex of a blackbox
    // This is only required when separating each state, where
    // any blackbox with multiple outputs is separated into
    // ones where only one output is 'active' and the rest
    // are stubbed
    let blackBoxTracker = HashMap<Edge<V, G>, Int64>()
    func AddRule(rule : RewriteRule<V, G>) {
        validRules.append(rule)
    }
    AddRule(GetStubRule())
    AddRule(GetBottomRule(signature))
    match(label) {
        case VALUE(_) =>
            AddRule(GetForkRule())
        case SIGNAL(_) =>
            AddRule(GetForkRule())
        case BUNDLER(_, _) =>
            AddRule(GetValueBundleRule(signature))
        case JOIN(_) =>
            AddRule(GetJoinRule(signature))
        case PRIMITIVE(_) =>
            AddRule(GetApplyRule(signature))
            if(allInstantaneous) {
                for(ann in signature.GetAnnihilators()) {
                    AddRule(GetAnnihiliationRule(ann))
                }
                for(ide in signature.GetIdentities()) {
                    AddRule(GetIdentifierRule(ide))
                }
            }
        case ENHANCED_PRIMITIVE(_) =>
            AddRule(GetCompositeRule(signature, true))
        case COMPOSITE(_) =>
            AddRule(GetCompositeRule(signature, true))
        case BLACKBOX(_) =>
            if(copyBlackBoxes) {
                AddRule(GetCopyBlackboxRule(blackBoxTracker))
                AddRule(GetForkBlackboxRule(blackBoxTracker))
            }
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
    ending : HashSet<TraversalElement<V, G>>,
    copyBlackBoxes!: Bool = false,
    allInstantaneous!: Bool = false
) : Unit
    where
        V <: ValueSymbol<V> & Equatable<V> & LessOrEqual<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
{
    let actionAtEdge = {
        e : Edge<V, G>, data : TraversalData<V, G> =>
            match(CheckAppropriateRules(
                e, f, signature,
                copyBlackBoxes: copyBlackBoxes, allInstantaneous: true
            )) {
                case Some(result) => result
                case None =>
                    let nextElements = HashSet<TraversalElement<V, G>>()
                    for(t in e.GetTargets()) {
                        let te = VERTEX(t.GetVertex())
                        if(!ending.contains(te)) {
                            nextElements.put(te)
                        }
                    }
                    nextElements
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
        nextElements
    }
    let startingElements = HashSet<TraversalElement<V, G>>()
    for(e in starting) {
        startingElements.put(e)
    }
    Traverse<V, G>(
        startingElements, actionAtVertex: actionAtVertex,
        actionAtEdge: actionAtEdge, revisit: true
    )
}
public func RewriteCombinational<V, G>(
    signature : Signature<V, G>,
    f : InterfacedHypergraph<V, G>,
    starting : HashSet<TraversalElement<V, G>>,
    copyBlackBoxes!: Bool
) : Unit
    where
        V <: ValueSymbol<V> & Equatable<V> & LessOrEqual<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
{
    RewriteCombinational(
        signature, f, starting, f.GetRightmostTraversalElements(),
        copyBlackBoxes: copyBlackBoxes
    )
}
public func RewriteCombinational<V, G>(
    signature : Signature<V, G>,
    f : InterfacedHypergraph<V, G>,
    copyBlackBoxes!: Bool
) : Unit
    where
        V <: ValueSymbol<V> & Equatable<V> & LessOrEqual<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
{
    RewriteCombinational(
        signature, f, f.GetLeftmostTraversalElements(),
        f.GetRightmostTraversalElements(), copyBlackBoxes: copyBlackBoxes
    )
}