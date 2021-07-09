/**
 * control.cj
 *
 * This file contains constant circuits that can be used to perform control flow operations (e.g. if then else)
 */
package circuits
import debug.*

/**
 * Create a hyp builder for an equality circuit
 * @param width The width of the inputs
 * @return The hyp builder for the equality circuit
 */
func CreateEquals(width!: Int64) : HypBuilder {
    if(width == 0) {
        HypBuilder()  
    } else if (width == 1) {
        let hb = HypBuilder(2,1)
        let and = hb.CreateEdge(XNOR)
        hb.AddConn(hb.GetInput(0), and.GetSource(0))
        hb.AddConn(hb.GetInput(1), and.GetSource(1))
        hb.AddConn(and.GetTarget(0), hb.GetOutput(0))
        hb
    } else {
        let hb = HypBuilder(width * 2, 1)
        // Computer for the first width - 1 bits
        let head = CreateEquals(width: width - 1)
        // Hook up the inputs of the subcomputation with the current one
        for(i in 0..width-1){
            hb.AddConn(hb.GetInput(i), head.GetInput(i).GetConn())
            hb.AddConn(hb.GetInput(i + width), head.GetInput(i + (width - 1)).GetConn())
        }
        hb.AddEdges(head.GetEdges())
        // We XNOR the width'th bits of the input
        let and1 = hb.CreateEdge(XNOR)
        hb.AddConn(hb.GetInput(width - 1), and1.GetSource(0))
        hb.AddConn(hb.GetInput((2 * width) - 1), and1.GetSource(1))
        // And the result of this computation with the result of the subcomputation
        let and2 = hb.CreateEdge(AND)
        hb.AddConn(head.GetOutput(0).GetConn(), and2.GetSource(0))
        hb.AddConn(and1.GetTarget(0), and2.GetSource(1))
        hb.AddConn(and2.GetTarget(0), hb.GetOutput(0))
        hb
    }
}
/**
 * Create a circ that tests if its two inputs are equal
 * @param width The width of the two inputs
 * @return The circuit for checking equality of two inputs
 */
external func Equals(width!: Int64) : Hypergraph {
    if(width < 1){
        throw NegativeWireException("Equals")
    }
    let hb = CreateEquals(width: width)
    hb.ToGraph()
}
/**
 * Create a circ that tests if its two inputs are equal
 * The two inputs must be of the same width
 * @param a The first input
 * @param b The second input
 * @return The composition of the inputs with an equality checking circuit
 */
external func Equals(a!: Hypergraph, b!: Hypergraph){
    if(a.GetN() != b.GetN()){
        throw DifferentLengthArgumentsException("Equals", a, b)
    }
    let eq = Equals(width: a.GetN())
    let input = Concat([a,b])
    input + eq
}

external func If(width!: Int64){
    if(width < 1){
        throw NegativeWireException("Equals")
    }
    Mux(width: width)
}

external func If(ifArg!: Hypergraph, thenArg!: Hypergraph, elseArg!: Hypergraph){
    if(thenArg.GetN() != elseArg.GetN()){
        throw DifferentLengthArgumentsException("If", thenArg, elseArg)
    }
    Mux(high: thenArg, low: elseArg, sel: ifArg)
}