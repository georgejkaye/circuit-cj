/**
 * graphs/assertions.cj
 *
 * @author George Kaye
 * @since 0.2
 */

package graphs

import assertions.*

func AssertAtMostOneInEdge<T, U, V, G>(t : T, u : U) : Option<EdgeConnection<V, G>>
    where
        T <: ContainsVertex<V, G>,
        U <: ContainsVertex<V, G>,
        V <: ValueSymbol<V> & Equatable<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
{
    let v = t.GetVertex()
    let w = u.GetVertex()
    match(v.GetInEdge()) {
        case None    => w.GetInEdge()
        case Some(ev) =>
            AssertHasParameter<Vertex<V, G>, Option<EdgeConnection<V, G>>>(
                w,
                None,
                { w : Vertex<V, G> => w.GetInEdge() },
                InEdge
            )
            Some(ev)
    }
}
func AssertAtMostOneInEdge<T, V, G>(ts : Array<T>) : Option<EdgeConnection<V, G>>
    where
        T <: ContainsVertex<V, G>,
        V <: ValueSymbol<V> & Equatable<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
{
    var inEdge = None<EdgeConnection<V, G>>
    for (t in ts) {
        let v = t.GetVertex()
        match(inEdge) {
            case Some(ec) =>
                AssertHasParameter<Vertex<V, G>, Option<EdgeConnection<V, G>>>(
                v,
                None,
                { w : Vertex<V, G> => w.GetInEdge() },
                InEdge
            )
            case None =>
                inEdge = v.GetInEdge()
        }
    }
    inEdge
}
public func AssertHasNoInEdge<V, G, T>(v : T) : Unit
    where
        V <: ValueSymbol<V> & Equatable<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>,
        T <: ContainsVertex<V, G>
{
    AssertIsNone(v.GetVertex().GetInEdge(), InEdge)
}
public func AssertHasNoOutEdges<V, G, T>(v : T) : Unit
    where
        V <: ValueSymbol<V> & Equatable<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>,
        T <: ContainsVertex<V, G>
{
    AssertEmpty(v.GetVertex().GetOutEdges(), OutEdges)
}
func AssertTargetsUnassigned<V, G, T>(targets : Array<T>) : Unit
    where
        V <: ValueSymbol<V> & Equatable<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>,
        T <: ContainsVertex<V, G> & ToString
{
    AssertArrayElementsHaveParameter<T, Option<EdgeConnection<V, G>>>(
        targets,
        None<EdgeConnection<V, G>>,
        { t => t.GetVertex().GetInEdge() },
        InEdge
    )
}
func AssertCompatibleInputOutput<V, G>(
    f : InterfacedHypergraph<V, G>,
    g : InterfacedHypergraph<V, G>
) : Unit
    where
        V <: ValueSymbol<V> & Equatable<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
{
    AssertArrayElementsHaveParameters<Port, Port, Port>(
        g.GetInputPorts(),
        f.GetOutputPorts(),
        { p : Port => p },
        { p : Port => p },
        Width
    )
}
func AssertGraphHasMinimumInputs<V, G>(f : InterfacedHypergraph<V, G>, i : Int64) : Unit
    where
        V <: ValueSymbol<V> & Equatable<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
{
    AssertArrayHasMinimumLength(f.GetInputPorts(), i)
}
func AssertGraphHasMinimumOutputs<V, G>(f : InterfacedHypergraph<V, G>, i : Int64) : Unit
    where
        V <: ValueSymbol<V> & Equatable<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
{
    AssertArrayHasMinimumLength(f.GetOutputPorts(), i)
}
public func AssertOwnedBy<V, G>(v : Vertex<V, G>, f : Hypergraph<V, G>) : Unit
    where
        V <: ValueSymbol<V> & Equatable<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
{
    if(v.GetOwner() != f) {
        throw BadOwnershipException(v, f, true)
    }
}
public func AssertAllOwnedBy<V, G, T>(
    vs : Array<T>, f : Hypergraph<V, G>
) : Unit
    where
        V <: ValueSymbol<V> & Equatable<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>,
        T <: ContainsVertex<V, G> & ToString
{
    AssertArrayElementsHaveParameter<T, Hypergraph<V, G>>(
        vs,
        f,
        { t : T => t.GetVertex().GetOwner() },
        Owner
    )
}
public func AssertAllOwnedBySame<V, G, T>(vs : Array<T>) : Hypergraph<V, G>
    where
        V <: ValueSymbol<V> & Equatable<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>,
        T <: ContainsVertex<V, G> & ToString
{
    AssertArrayAllSameParameter<T, Hypergraph<V, G>>(
        vs,
        { t : T => t.GetVertex().GetOwner() },
        Owner
    )
}
public func AssertNotOwnedBy<V, G>(e : Edge<V, G>, f : Hypergraph<V, G>) : Unit
    where
        V <: ValueSymbol<V> & Equatable<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
{
    if(e.GetOwner() == f) {
        throw BadOwnershipException(e, f, false)
    }
}
class BadOwnershipException<V, G> <: Exception
    where
        V <: ValueSymbol<V> & Equatable<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
{
    public init(e : Edge<V, G>, f : Hypergraph<V, G>, isOwned : Bool) {
        let isOwnedString = if(isOwned) {
            "is"
        } else {
            "is not"
        }
        ErrorMsg("Required that ${e} ${isOwnedString} owned by ${f} but it is")
    }
    public init(v : Vertex<V, G>, f : Hypergraph<V, G>, isOwned : Bool) {
        let isOwnedString = if(isOwned) {
            "is"
        } else {
            "is not"
        }
        ErrorMsg("Required that ${v} ${isOwnedString} owned by ${f} but it is")
    }
}