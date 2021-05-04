package library

import hypergraphs.*

func DecToBin(w : Int64, x : Int64, signed: Bool){
    if(w < 1){
        throw NotEnoughBitsException()
    }
    var num = signed ? x < 0 ? x + (2 ** w) : x : x
    let bin = ArrayList<Bool>(w, {x : Int64 => false})

    for(i in 0..w-1){
        let rem = num % 2 == 1
        bin.set(w-i-1, rem)
        num = num / 2
    }
    if(signed && x < 0){
        bin.set(0, true)
    }
    return bin
}

func ValueFromInt(x : Int64, width!: Int64, signed!: Bool, name!: String = ""){
    let bin = DecToBin(width, x, signed)
    let values : ArrayList<Hypergraph> = map(bin, {b : Bool => b ? True() : False()})
    return Par(values, name: name)
}

external func SignedValueFromInt(x : Int64, width!: Int64, name!: String = ""){
    ValueFromInt(x, width: width, signed: true, name: name) 
}
external func UnsignedValueFromInt(x : Int64, width!: Int64, name!: String = ""){
    ValueFromInt(x, width: width, signed: false, name: name) 
}

external func Zero(width!: Int64 = 1){
    if(width < 1){
        throw NotEnoughBitsException()
    }
    Par(False(), width)
}

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
    Seq([
        Par(Copy(2), Identity(1)),
        Par(XorGate(), Swap(2,1)),
        Par(Copy(2), Identity(2)),
        Par([XorGate(), AndGate(), AndGate()]),
        Par(Identity(1, label: sum), OrGate(label: cout))
    ])
}

external func Adder(width!: Int64, sum!: String = "", cout!: String = "") : Hypergraph {
    if(width < 1){
        throw NotEnoughBitsException()
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
    ])
}

external func Adder(width!: Int64, 
                    a!: Hypergraph, 
                    b!: Hypergraph, 
                    cin!: Hypergraph = Zero(width: 1), 
                    sum!: String = "", 
                    cout!: String = "") : Hypergraph {
    if(a.GetN() != width){
        throw BadInputException("Adder", "a", width, a.GetName(), a.GetN())
    }
    if(b.GetN() != width){
        throw BadInputException("Adder", "b", width, b.GetName(), b.GetN())
    }
    if(cin.GetN() != 1){
        throw BadInputException("Adder", "cin", 1, cin.GetName(), cin.GetN())
    }
    Seq(Output([a,b,cin]), Adder(width: width, sum: sum, cout: cout))
}

external func Plus(width!: Int64, 
                   a!: Hypergraph = Identity(width), 
                   b!: Hypergraph = Identity(width), 
                   sum!: String = "", 
                   cout!: String = "") : Hypergraph {
    Adder(width: width, a: a, b: b, cin: Zero(width: 1), sum: sum, cout: cout)
}