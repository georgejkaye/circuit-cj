/**
 * arithmetic.cj
 *
 * This file contains constant arithmetic circuits that can be defined directly as hypergraphs
 * This is more efficient (although less elegant) than defining them by combining other constructs
 */
package circuits
import debug.*

/**
 * Create a HypBuilder for a half adder
 * @param sum   The name of the sum port
 * @param carry The name of the carry port
 * @param bit   The bit this half adder is working on
 * @return The hyp builder for this half adder
 */
func CreateHalfAdder(sum!: String = "", carry!: String = "", bit!: Int64 = 0) {
    if(bit < 0){
        throw NegativeWireException("HalfAdder")
    }   
    // Create a builder
    let hb = HypBuilder(2, 2, [NewWire(sum, bit), NewWire(carry, bit)])
    // Fork the inputs
    let fork1 = hb.CreateEdge(FORK, [hb.GetInput(0)])
    let fork2 = hb.CreateEdge(FORK, [hb.GetInput(1)])
    // Compute sum and carry
    let xorLhs = fork1.GetTarget(0)
    let xorRhs = fork2.GetTarget(0)
    let andLhs = fork1.GetTarget(1)
    let andRhs = fork2.GetTarget(1)
    let xor = hb.CreateEdge(XOR, [xorLhs, xorRhs], [hb.GetOutput(0)])
    let and = hb.CreateEdge(AND, [andLhs, andRhs], [hb.GetOutput(1)])
    // Return the builder
    hb
}
/**
 * Create a fresh half adder 
 * @param sum   The name of the sum port
 * @param carry The name of the carry port
 * @param bit   The bit this half adder is working on
 * @param name  The name of the new circuit
 * @return The fresh half adder
 */
public func HalfAdder(sum!: String = "", carry!: String = "", bit!: Int64 = 0, name!: String = "") : Hypergraph {
    Debug("HalfAdder", "Making half adder; outputs sum='${sum}', carry='${carry}'")
    let hb = CreateHalfAdder(sum: sum, carry: carry, bit: bit)
    hb.ToGraph()
}
/**
 * Create a fresh half adder and compose it to some existing circuits
 * @param a     The hypergraph to connect to the a port (outputs = 1)
 * @param b     The hypergraph to connect to the b port (outputs = 1)
 * @param sum   The name of the sum port
 * @param carry The name of the carry port
 * @param bit   The bit this half adder is working on
 * @param name  The name of the new circuit
 * @return The fresh half adder
 */
public func HalfAdder(a!: Hypergraph, b!: Hypergraph, sum!: String = "", carry!: String = "", bit!: Int64 = 0, name!: String = "") : Hypergraph {
    Debug("HalfAdder", "Making half adder; inputs a='${a.GetName()}' and b='${b.GetName()}'; outputs sum='${sum}', carry='${carry}'")
    if(a.GetN() != 1){
        throw BadInputGraphException("HalfAdder", "a", 1, a.GetName(), a.GetN())
    }
    if(b.GetN() != 1){
        throw BadInputGraphException("HalfAdder", "b", 1, b.GetName(), b.GetN())
    }
    Seq(Concat([a,b]), HalfAdder(sum: sum, carry: carry, bit: bit), name: name)
}
/**
 * Create a HypBuilder for a full adder
 * @param sum   The name of the sum port
 * @param cout  The name of the carry port
 * @param bit   The bit this full adder is working on
 * @return The hyp builder for this full adder
 */
func CreateFullAdder(sum!: String = "", cout!: String = "", bit!: Int64 = 0) : HypBuilder {
    if(bit < 0){
        throw NotEnoughBitsException("FullAdder")
    }
    // Create a builder
    let hb = HypBuilder(3, 2, [NewWire(sum, bit), NewWire(cout, 0)])
    // Fork all the inputs
    let fork1 = hb.CreateEdge(FORK, [hb.GetInput(0)])
    let fork2 = hb.CreateEdge(FORK, [hb.GetInput(1)])
    let fork3 = hb.CreateEdge(FORK, [hb.GetInput(2)])

    // The half adder bit
    let xorLhs = fork1.GetTarget(0)
    let xorRhs = fork2.GetTarget(0)
    let andLhs = fork1.GetTarget(1)
    let andRhs = fork2.GetTarget(1)
    let xor1 = hb.CreateEdge(XOR, [xorLhs, xorRhs])
    let and1 = hb.CreateEdge(AND, [andLhs, andRhs])

    // Bring in the carry
    let forkv = xor1.GetTarget(0)
    let fork4 = hb.CreateEdge(FORK, [forkv])

    let xor2Lhs = fork4.GetTarget(0)
    let xor2Rhs = fork3.GetTarget(0)
    let t = hb.GetOutput(0)
    let xor2 = hb.CreateEdge(XOR, [xor2Lhs, xor2Rhs], [t])

    let and2Lhs = fork3.GetTarget(1)
    let and2Rhs = fork4.GetTarget(1)
    let and2 = hb.CreateEdge(AND, [and2Lhs, and2Rhs])

    let or1Lhs = and2.GetTarget(0)
    let or1Rhs = and1.GetTarget(0)
    let or1 = hb.CreateEdge(OR, [or1Lhs, or1Rhs], [hb.GetOutput(1)])
    // Return the builder
    hb
}
/**
 * Create a fresh full adder 
 * @param sum   The name of the sum port
 * @param cout  The name of the carry port
 * @param bit   The bit this full adder is working on 
 * @param name  The name of the new circuit
 * @return The fresh full adder
 */
public func FullAdder(sum!: String = "", cout!: String = "", bit!: Int64 = 0, name!: String = ""){
    Debug("FullAdder", "Making full adder; outputs sum='${sum}', cout='${cout}'")
    let hb = CreateFullAdder(sum: sum, cout: cout, bit: bit)
    hb.ToGraph()
}
/**
 * Create a fresh half adder and compose it to some existing circuits
 * @param a     The hypergraph to connect to the a port (outputs = 1)
 * @param b     The hypergraph to connect to the b port (outputs = 1)
 * @param cin   The hypergraph to connect to the cin port (outputs = 1)
 * @param sum   The name of the sum port
 * @param carry The name of the carry port
 * @param bit   The bit this half adder is working on
 * @param name  The name of the new circuit
 * @return The fresh half adder
 */
public func FullAdder(a!: Hypergraph, b!: Hypergraph, cin!: Hypergraph, sum!: String = "", cout!: String = "", bit!: Int64 = 0, name!: String = "") : Hypergraph {
    Debug("FullAdder", "Making full adder; inputs a='${a.GetName()}', b='${b.GetName()} and cin='${cin.GetName()}; outputs sum='${sum}', cout='${cout}'")
    if(a.GetN() != 1){
        throw BadInputGraphException("FullAdder", "a", 1, a.GetName(), a.GetN())
    }
    if(b.GetN() != 1){
        throw BadInputGraphException("FullAdder", "b", 1, b.GetName(), b.GetN())
    }
    if(cin.GetN() != 1){
        throw BadInputGraphException("FullAdder", "cin", 1, cin.GetName(), cin.GetN())
    }
    Seq(Concat([a,b,cin]), FullAdder(sum: sum, cout: cout, bit: bit, name: name))
}
/**
 * Create a HypBuilder for an adder of arbitrary width
 * @param width The width of this adder
 * @param bit   The initial bit of the output
 * @param sum   The name of the sum bus
 * @param cout  The name of the cout port
 * @return The hyp builder for the appropriate adder 
 */
func CreateAdder(width!: Int64, bit!: Int64 = 0, sum!: String = "", cout!: String = "") : HypBuilder {
    if(width < 1 || bit < 0){
         throw NotEnoughBitsException("Adder")
    }
    if(width == 1){
        CreateHalfAdder(sum: sum, carry: cout, bit: bit)
    } else {
        // let n = width - 1
        // // Create the 'head' adder to deal with the first bit
        // let headAdder = CreateFullAdder(sum: sum, bit: bit)
        // // Create the 'tail' adder to deal with the rest of the bits
        // let tailAdder = CreateAdder(width: n, sum: sum, cout: cout, bit: bit + 1)
        // // Create the complete adder builder
        // let completeAdder = HypBuilder()
        // // Add all the edges from the head and the tail
        // completeAdder.AddEdges(headAdder.GetEdges())
        // completeAdder.AddEdges(tailAdder.GetEdges())
        // // Put the inputs from the head and the tail in the right order
        // // head[0] tail[0..n] head[1] tail[n..n*2] head[2]
        // completeAdder.AddInput(headAdder.GetInput(0))
        // for(i in 0..n){
        //     completeAdder.AddInput(tailAdder.GetInputs()[i])
        // }
        // completeAdder.AddInput(headAdder.GetInput(1))
        // for(i in 0..n){
        //     completeAdder.AddInput(tailAdder.GetInputs()[n+i])
        // }
        // completeAdder.AddInput(headAdder.GetInput(2))
        // // Put the outputs in too: sum from the head and everything from the tail
        // completeAdder.AddOutput(headAdder.GetOutput(0))
        // for(out in tailAdder.GetOutputs()){
        //     completeAdder.AddOutput(out)
        // }
        // // Need to hook up the carry of the head to the relevant port of the tail
        // let carryOut = headAdder.GetOutput(1).GetConn()
        // let carryIn = tailAdder.GetInput(n * 2).GetConn()
        // carryOut.SetConn(carryIn)
        // // Return the complete builder
        // completeAdder

        let n = width - 1
        let subAdder = CreateAdder(width: n, sum: sum, cout: cout, bit: bit + 1)
        let bitAdder = CreateFullAdder(sum: sum, bit: bit)

        let completeAdder = HypBuilder()
        completeAdder.AddEdges(subAdder.GetEdges())
        completeAdder.AddEdges(bitAdder.GetEdges())

        for(i in 0..n){
            completeAdder.AddInput(subAdder.GetInput(i))
            completeAdder.AddOutput(subAdder.GetOutput(i))
        }
        completeAdder.AddInput(bitAdder.GetInput(0))
        for(i in 0..n){
            completeAdder.AddInput(subAdder.GetInput(i + n))
        }
        completeAdder.AddInput(bitAdder.GetInput(1))
        completeAdder.AddConn(subAdder.GetOutput(n).GetConn(), bitAdder.GetInput(2).GetConn())
        completeAdder.AddOutput(bitAdder.GetOutput(0))
        completeAdder.AddOutput(bitAdder.GetOutput(1))
        completeAdder

    }
}
/**
 * Create a fresh adder of arbitrary width
 * @param width The width of the adder
 * @param sum   The name of the sum bus
 * @param cout  The name of the cout port
 * @param name  The name of the fresh adder
 * @return The fresh adder
 */
public func Adder(width!: Int64, sum!: String = "", cout!: String = "", name!: String = "") {
    Debug("Adder", "Making n-bit adder of width ${width}, sum='${sum}', cout='${cout}'")
    let adderBuilder = CreateAdder(width: width, bit: 0, sum: sum, cout: cout)
    let g = adderBuilder.ToGraph(name)
    g
}
/**
 * Create a fresh n-bit adder and compose it to some existing circuits
 * @param width The width of the adder
 * @param a     The hypergraph to connect to the a port (outputs = width)
 * @param b     The hypergraph to connect to the b port (outputs = width)
 * @param cin   The hypergraph to connect to the cin port (outputs = 1)
 * @param sum   The name of the sum bus
 * @param cout  The name of the carry port
 * @param bit   The bit this half adder is working on
 * @param name  The name of the new circuit
 * @return The fresh half adder
 */
public func Adder(a: Hypergraph, b: Hypergraph, cin!: Hypergraph = Zero(width: 1), sum!: String = "", cout!: String = "", name!: String = "") : Hypergraph {
    Debug("Adder", "Making n-bit adder with inputs a='${a.GetName()}', b='${b.GetName()}', cin='${cin.GetName()}'")
    if(a.GetN() != b.GetN()){
        throw DifferentLengthArgumentsException("Adder", a, b)
    }
    if(cin.GetN() != 1){
        throw BadInputGraphException("Adder", "cin", 1, cin.GetName(), cin.GetN())
    }
    Seq(Concat([a,b,cin]), Adder(width: a.GetN(), sum: sum, cout: cout), name: name)
}
/**
 * Create a fresh plus circuit of arbitrary width
 * A plus is just an adder that initialises the first carry in to an infinite wavelength of zeroes and discards the final carry out
 * @param width The width of the inputs
 * @param output The name of the output bus
 * @param name The name of the new circuit
 * @return The new plus circuit
 */
public func Plus(width!: Int64, label!: String = "", name!: String = "") : Hypergraph {
    Debug("Plus", "Making plus of width ${width}")
    let adder = Adder(width: width, sum: label)
    Drop(adder, width, name: name)
}
/**
 * Create a fresh plus circuit of arbitrary width and compose it to some existing circuits
 * The width is determined by the inputs, which must be the same length
 * A plus is just an adder that initialises the first carry in to zero discards the final carry out
 * @param a The lhs argument to the plus
 * @param b The rhs argument to the plus
 * @param output The name of the output bus
 * @param name The name of the new circuit
 * @return The new plus circuit
 */
public func Plus(a: Hypergraph, b: Hypergraph, label!: String = "") : Hypergraph {
    Debug("Plus", "Making plus with inputs a='${a.GetName()}' and b='${b.GetName()}'")
    if(a.GetN() != b.GetN()){
        throw BusesNotSameSizeException("Plus", a.GetN(), b.GetN())
    }
    let plus = Plus(width: a.GetN(), label: label)
    Seq(Concat([a,b]), plus)
}

