package library

import hypergraphs.*
import debug.*

/**
 * Adders
 */

external func HalfAdder(a!: Hypergraph, b!: Hypergraph, sum!: String = "", carry!: String = "") : Hypergraph {
    if(a.GetN() != 1){
        throw BadInputException("HalfAdder", "a", 1, a.GetName(), a.GetN())
    }
    if(b.GetN() != 1){
        throw BadInputException("HalfAdder", "b", 1, b.GetName(), b.GetN())
    }
    Seq(Output([a,b]), HalfAdder(sum: sum, carry: carry))
}

external func HalfAdder(sum!: String = "", carry!: String = "") : Hypergraph {
    Debug("Half adder", "Making half adder, sum='${sum}', carry='${carry}'")
    Seq(Copy(2), Par(XorGate(output: sum), AndGate(output: carry)))
}

external func FullAdder(a!: Hypergraph, b!: Hypergraph, cin!: Hypergraph, sum!: String = "", cout!: String = "", bit!: Int64 = 0, name!: String = "") : Hypergraph {
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

external func FullAdder(sum!: String = "", cout!: String = "", bit!: Int64 = 0, name!: String = "") : Hypergraph {
    Debug("Full adder", "Making full adder, sum='${sum}', cout='${cout}'")
    if(bit < 0){
        throw NotEnoughBitsException("FullAdder")
    }
    Seq([
        Par(Copy(2), Identity(1)),
        Par(XorGate(), Swap(2,1)),
        Par(Copy(2), Identity(2)),
        Par([XorGate(output : sum, elem: bit), AndGate(), AndGate()]),
        Par(Identity(1), OrGate(output: cout, elem: 0))
    ], name: name)
}

external func Adder(width!: Int64, bit!: Int64 = 0, sum!: String = "", cout!: String = "", name!: String = "") : Hypergraph {
    Debug("Adder", "Making n-bit adder of width ${width}, sum='${sum}', cout='${cout}'")
    if(width < 1 || bit < 0){
        throw NotEnoughBitsException("Adder")
    }
    if(width == 1){
        return FullAdder(sum: sum, cout: cout, bit: bit)
    }
    let n = width - 1
    Seq([
        Par([Identity(1), Swap(n, 1), Identity(width)]),
        Par(Identity(2), Swap(2 * n, 1)),
        Par(FullAdder(sum: sum, bit: bit), Identity(2 * n)),
        Par(Identity(1), Swap(1, 2 * n)),
        Par(Identity(1), Adder(width: n, bit: bit+1, sum: sum, cout: cout))
    ], name: name)
}

// external func Adder(width!: Int64, 
//                     a!: Hypergraph, 
//                     b!: Hypergraph, 
//                     cin!: Hypergraph = Zero(width: 1), 
//                     sum!: String = "", 
//                     cout!: String = "", name!: String = "") : Hypergraph {
//     if(a.GetN() != width){
//         throw BadInputException("Adder", "a", width, a.GetName(), a.GetN())
//     }
//     if(b.GetN() != width){
//                 throw BadInputException("Adder", "b", width, b.GetName(), b.GetN())
//     }
//     if(cin.GetN() != 1){
//         throw BadInputException("Adder", "cin", 1, cin.GetName(), cin.GetN())
//     }
//     Seq(Output([a,b,cin]), Adder(width: width, sum: sum, cout: cout), name: name)
// }

external func Plus(width!: Int64, output!: String, name!: String = ""){
    Debug("Plus", "Making plus of width ${width}")
    let add = Seq(Par(Identity(2*width), Zero(width: 1)), Adder(width: width, sum: output))
    Drop(add, width, name: name)
}

external func Plus(width!: Int64, 
                   a!: Hypergraph,
                   b!: Hypergraph, 
                   output!: String = "", name!: String = "") : Hypergraph {
    let plus = Plus(width: width, output: output)
    Seq(Output([a,b]), plus, name: name)
}
