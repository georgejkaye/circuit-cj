/**
 * This file contains constant circuits that can be defined directly as hypergraphs
 * This is more efficient (although less elegant) than defining them by combining other constructs
 */

package hypergraphs

import debug.*

func PairListToMap<K,V>(ps : ArrayList<K * V>) where K <: Hashable, K <: Equatable {
    let mb = MapBuilder<K,V>()
    for((k, v) in ps){
        mb.add(k,v)
    }
    mb
}

func CreateHalfAdder(sum!: String = "", carry!: String = "", bit!: Int64 = 0) : HypBuilder {
    if(bit < 0){
        throw NegativeWireException("HalfAdder")
    }   
    // Create a builder
    let hb = HypBuilder(2, 2, [NewWire(sum, bit), NewWire(carry, bit)])
    // Fork the inputs
    let fork1 = hb.CreateEdge(FORK, [hb.inputs[0]])
    let fork2 = hb.CreateEdge(FORK, [hb.inputs[1]])
    // Compute sum and carry
    let xor = hb.CreateEdge(XOR, [fork1.targets[0], fork2.targets[0]], [hb.outputs[0]])
    let and = hb.CreateEdge(AND, [fork1.targets[1], fork2.targets[1]], [hb.outputs[1]])
    // Return the builder
    hb
}

external func HalfAdder(sum!: String = "", carry!: String = "", bit!: Int64 = 0, name!: String = "") : Hypergraph {
    Debug("HalfAdder", "Making half adder; outputs sum='${sum}', carry='${carry}'")
    let hb = CreateHalfAdder(sum: sum, carry: carry, bit: bit)
    hb.ToGraph()
}

external func HalfAdder(a!: Hypergraph, b!: Hypergraph, sum!: String = "", carry!: String = "", bit!: Int64 = 0, name!: String = "") : Hypergraph {
    Debug("HalfAdder", "Making half adder; inputs a='${a.GetName()}' and b='${b.GetName()}'; outputs sum='${sum}', carry='${carry}'")
    if(a.GetN() != 1){
        throw BadInputException("HalfAdder", "a", 1, a.GetName(), a.GetN())
    }
    if(b.GetN() != 1){
        throw BadInputException("HalfAdder", "b", 1, b.GetName(), b.GetN())
    }
    Seq(Output([a,b]), HalfAdder(sum: sum, carry: carry, bit: bit), name: name)
}

func CreateFullAdder(sum!: String = "", cout!: String = "", bit!: Int64 = 0) : HypBuilder {
    if(bit < 0){
        throw NotEnoughBitsException("FullAdder")
    }
    // Create a builder
    let hb = HypBuilder(3, 2, [NewWire(sum, bit), NewWire(cout, 0)])
    // Fork all the inputs
    let fork1 = hb.CreateEdge(FORK, [hb.inputs[0]])
    let fork2 = hb.CreateEdge(FORK, [hb.inputs[1]])
    let fork3 = hb.CreateEdge(FORK, [hb.inputs[2]])
    // The half adder bit
    let xor1 = hb.CreateEdge(XOR, [fork1.targets[0], fork2.targets[0]])
    let and1 = hb.CreateEdge(AND, [fork1.targets[1], fork2.targets[1]])
    // Bring in the carry
    let fork4 = hb.CreateEdge(FORK, [xor1.targets[0]])
    let xor2 = hb.CreateEdge(XOR, [fork4.targets[0], fork3.targets[0]], [hb.outputs[0]])
    let and2 = hb.CreateEdge(AND, [fork3.targets[1], fork4.targets[1]])
    let or1 = hb.CreateEdge(OR, [and2.targets[0], and1.targets[0]], [hb.outputs[1]])
    // Return the builder
    hb
}

external func FullAdder(name!: String = "", sum!: String = "", cout!: String = "", bit!: Int64 = 0){
    Debug("FullAdder", "Making full adder; outputs sum='${sum}', cout='${cout}'")
    let hb = CreateFullAdder(sum: sum, cout: cout, bit: bit)
    hb.ToGraph()
}

external func FullAdder(a!: Hypergraph, b!: Hypergraph, cin!: Hypergraph, sum!: String = "", cout!: String = "", bit!: Int64 = 0, name!: String = "") : Hypergraph {
    Debug("FullAdder", "Making full adder; inputs a='${a.GetName()}', b='${b.GetName()} and cin='${cin.GetName()}; outputs sum='${sum}', cout='${cout}'")
    if(a.GetN() != 1){
        throw BadInputException("FullAdder", "a", 1, a.GetName(), a.GetN())
    }
    if(b.GetN() != 1){
        throw BadInputException("FullAdder", "b", 1, b.GetName(), b.GetN())
    }
    if(cin.GetN() != 1){
        throw BadInputException("FullAdder", "cin", 1, cin.GetName(), cin.GetN())
    }
    Seq(Output([a,b,cin]), FullAdder(sum: sum, cout: cout, bit: bit, name: name))
}

/**
 * Adders
 */
func CreateAdder(width!: Int64, bit!: Int64 = 0, sum!: String = "", cout!: String = "") : HypBuilder {
    if(width < 1 || bit < 0){
         throw NotEnoughBitsException("Adder")
    }
    if(width == 1){
        CreateFullAdder(sum: sum, cout: cout, bit: bit)
    } else {
        let n = width - 1
        // Create the 'head' adder to deal with the first bit
        let headAdder = CreateFullAdder(sum: sum, bit: bit)
        // Create the 'tail' adder to deal with the rest of the bits
        let tailAdder = CreateAdder(width: n, sum: sum, cout: cout, bit: bit + 1)
        // Create the complete adder builder
        let completeAdder = HypBuilder()
        // Add all the edges from the head and the tail
        completeAdder.edges.addAll(headAdder.edges)
        completeAdder.edges.addAll(tailAdder.edges)
        // Put the inputs from the head and the tail in the right order
        // head[0] tail[0..n] head[1] tail[n..n*2] head[2]
        completeAdder.inputs.add(headAdder.inputs[0])
        for(i in 0..n){
            completeAdder.inputs.add(tailAdder.inputs[i])
        }
        completeAdder.inputs.add(headAdder.inputs[1])
        for(i in 0..n){
            completeAdder.inputs.add(tailAdder.inputs[n+i])
        }
        completeAdder.inputs.add(headAdder.inputs[2])
        // Put the outputs in too: sum from the head and sum+carry from the tail
        completeAdder.outputs.add(headAdder.outputs[0])
        for(out in tailAdder.outputs){
            completeAdder.outputs.add(out)
        }

        // Need to hook up the carry of the head to the relevant port of the tail
        let carryOut = headAdder.GetConnL(headAdder.outputs[1])
        let carryIn = tailAdder.GetConnR(tailAdder.inputs[n * 2])
        completeAdder.AddConn(carryOut, carryIn)
        // Add in the rest of the connections
        for((t, s) in headAdder.GetConns().toMap()){
            if(t != carryOut){
                completeAdder.AddConn(t, s)
            }
        }
        for((t, s) in tailAdder.GetConns().toMap()){
            completeAdder.AddConn(t,s)
        }
        // Return the complete builder
        completeAdder
    }
}

external func Adder(width!: Int64, sum!: String = "", cout!: String = "") {
    Debug("Adder", "Making n-bit adder of width ${width}, sum='${sum}', cout='${cout}'")
    let adderBuilder = CreateAdder(width: width, bit: 0, sum: sum, cout: cout)
    let x = adderBuilder.ToGraph()
    print("${x}\n")
    x
}

external func Adder(width!: Int64, a!: Hypergraph, b!: Hypergraph, cin!: Hypergraph = Zero(width: 1), sum!: String = "", cout!: String = "", name!: String = "") : Hypergraph {
    Debug("Adder", "Making n-bit adder of width ${width} with inputs a='${a.GetName()}', b='${b.GetName()}', cin='${cin.GetName()}'")
    if(a.GetN() != width){
        throw BadInputException("Adder", "a", width, a.GetName(), a.GetN())
    }
    if(b.GetN() != width){
                throw BadInputException("Adder", "b", width, b.GetName(), b.GetN())
    }
    if(cin.GetN() != 1){
        throw BadInputException("Adder", "cin", 1, cin.GetName(), cin.GetN())
    }
    Seq(Output([a,b,cin]), Adder(width: width, sum: sum, cout: cout), name: name)
}

external func Plus(width!: Int64, output!: String = "", name!: String = "") : Hypergraph {
    Debug("Plus", "Making plus of width ${width}")
    let adder = Adder(width: width, sum: output)
    print("adder\n")
    let plus = Seq(Par(Identity(2 * width), Zero(width: 1)), adder)
    Drop(plus, width, name: name)
}

external func Plus(a!: Hypergraph, b!: Hypergraph, output!: String = "", name!: String = "") : Hypergraph {
    Debug("Plus", "Making plus with inputs a='${a.GetName()}' and b='${b.GetName()}'")
    if(a.GetN() != b.GetN()){
        throw BusesNotSameSizeException("Plus", a.GetN(), b.GetN())
    }
    let plus = Plus(width: a.GetN(), output: output)
    Seq(Output([a,b]), plus, name: name)
}
