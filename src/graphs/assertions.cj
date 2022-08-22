/**
 * graphs/assertions.cj
 *
 * @author George Kaye
 * @since 0.2
 */

package graphs

import assertions.*

func AssertOwned<T,U>(t : T) : U where T <: Ownable<U>, U <: ToString {
    AssertIsNotNone<U>(t.GetOwner(), Owner)
}
func AssertAtMostOneInEdge<T, U>(t : T, u : U) : Option<EdgeConnection> where T <: ContainsVertex, U <: ContainsVertex {
    let v = t.GetVertex()
    let w = u.GetVertex()
    match(v.GetInEdge()) {
        case None    => w.GetInEdge()
        case Some(ev) =>
            println("${v} has in edge ${ev}, so now checking that ${w} has none")
            AssertHasParameter<Vertex, Option<EdgeConnection>>(
                w,
                None,
                { w : Vertex => w.GetInEdge() },
                InEdge
            )
            Some(ev)
    }
}
public func AssertVertexHasNoInEdge(v : Vertex) : Unit {
    AssertIsNone(v.GetInEdge(), InEdge)
}
func AssertTargetsUnassigned(targets : Array<Vertex>) : Unit {
    AssertArrayElementsHaveParameter<Vertex, Option<EdgeConnection>>(
        targets,
        None,
        { v : Vertex => v.GetInEdge() },
        InEdge
    )
}
func AssertCompatibleInputOutput(
    f : InterfacedHypergraph,
    g : InterfacedHypergraph
) : Unit {
    AssertArrayElementsHaveParameters<Port, Port, Port>(
        g.GetInputPorts(),
        f.GetOutputPorts(),
        { p : Port => p },
        { p : Port => p },
        Width
    )
}
func AssertGraphHasMinimumInputs(f : InterfacedHypergraph, i : Int64) : Unit {
    AssertArrayHasMinimumLength(f.GetInputPorts(), i)
}
func AssertGraphHasMinimumOutputs(f : InterfacedHypergraph, i : Int64) : Unit {
    AssertArrayHasMinimumLength(f.GetOutputPorts(), i)
}