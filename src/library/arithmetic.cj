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
    Seq(Copy(2), Par(XorGate(label: sum), AndGate(label: carry)))
}

external func FullAdder(a!: Hypergraph, b!: Hypergraph, cin!: Hypergraph, sum!: String = "", cout!: String = "") : Hypergraph {
    if(a.GetN() != 1){
        throw BadInputException("FullAdder", "a", 1, a.GetName(), a.GetN())
    }
    if(b.GetN() != 1){
        throw BadInputException("FullAdder", "b", 1, b.GetName(), b.GetN())
    }
    if(cin.GetN() != 1){
        throw BadInputException("FullAdder", "cin", 1, cin.GetName(), cin.GetN())
    }
    Seq(Output([a,b,cin]), FullAdder(sum: sum, cout: cout))
}

external func FullAdder(sum!: String = "", cout!: String = "") : Hypergraph {
    Debug("Full adder", "Making full adder, sum='${sum}', cout='${cout}'")
    Seq([
        Par(Copy(2), Identity(1)),
        Par(XorGate(), Swap(2,1)),
        Par(Copy(2), Identity(2)),
        Par([XorGate(), AndGate(), AndGate()]),
        Par(Identity(1, label: sum), OrGate(label: cout))
    ])
}

external func Adder(width!: Int64, sum!: String = "", cout!: String = "", name!: String = "") : Hypergraph {
    Debug("Adder", "Making n-bit adder of width ${width}, sum='${sum}', cout='${cout}'")
    if(width < 1){
        throw NotEnoughBitsException("Adder")
    }
    if(width == 1){
        return FullAdder(sum: sum, cout: cout)
    }
    let n = width - 1
    Seq([
        Par([Identity(1), Swap(n, 1), Identity(width)]),
        Par(Identity(2), Swap(2 * n, 1)),
        Par(FullAdder(), Identity(2 * n)),
        Par(Identity(1), Swap(1, 2 * n)),
        Par(Identity(1, label: sum), Adder(width: n, sum: sum, cout: cout))
    ], name: name)
}

external func Adder(width!: Int64, 
                    a!: Hypergraph, 
                    b!: Hypergraph, 
                    cin!: Hypergraph = Zero(width: width), 
                    sum!: String = "", 
                    cout!: String = "", name!: String = "") : Hypergraph {
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

external func Plus(width!: Int64, 
                   a!: Hypergraph = Identity(width), 
                   b!: Hypergraph = Identity(width), 
                   sum!: String = "", name!: String = "") : Hypergraph {
    Debug("Plus", "Making plus of width ${width}")
    let add = Adder(width: width, a: a, b: b, cin: Zero(width: 1), sum: sum, name: name)
    Drop(add, width)
}
