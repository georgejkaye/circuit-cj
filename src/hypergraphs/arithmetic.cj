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

func HalfAdderAtoms(sum!: String = "", carry!: String = "", bit!: Int64 = 0) {
    if(bit < 0){
        throw NegativeWireException("HalfAdder")
    }

    let sumWire = NewWire(sum, bit)
    let carryWire = NewWire(carry, bit)

    let (t1, s1) = (Target(), Source())
    let (t2, s2) = (Target(), Source())
    let (t3, s3) = (Target(), Source())
    let (t4, s4) = (Target(), Source())
    let (t5, s5) = (Target(), Source())
    let (t6, s6) = (Target(), Source())
    let (t7, s7) = (Target(), Source(sumWire))
    let (t8, s8) = (Target(), Source(carryWire))

    let inputs = [t1,t2]
    let fork1 = Edge(FORK, [s1], [t3,t4])
    let fork2 = Edge(FORK, [s2], [t5,t6])
    let xor = Edge(XOR, [s3,s5], [t7])
    let and = Edge(AND, [s4,s6], [t8])
    let edges = [fork1, fork2, xor, and]
    let outputs = [s7,s8]

    let conns = MapBuilder<Target, Source>()
    conns.add(t1,s1)
    conns.add(t2,s2)
    conns.add(t3,s3)
    conns.add(t4,s4)
    conns.add(t5,s5)
    conns.add(t6,s6)
    conns.add(t7,s7)
    conns.add(t8,s8)

    (ArrayList<Edge>(edges), ArrayList<Target>(inputs), ArrayList<Source>(outputs), conns)
}

external func HalfAdder(sum!: String = "", carry!: String = "", bit!: Int64 = 0, name!: String = "") : Hypergraph {
    Debug("HalfAdder", "Making half adder; outputs sum='${sum}', carry='${carry}'")
    let (edges, inputs, outputs, conns) = HalfAdderAtoms(sum: sum, carry: carry, bit: bit)
    Hypergraph(edges, inputs, outputs, conns)
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

func FullAdderAtoms(sum!: String = "", cout!: String = "", bit!: Int64 = 0) : ArrayList<Edge> * ArrayList<Target> * ArrayList<Source> * ArrayList<Target * Source> {
    if(bit < 0){
        throw NotEnoughBitsException("FullAdder")
    }
    
    let sumWire = NewWire(sum, bit)
    let carryWire = NewWire(cout, 0)

    let (t1, s1) = (Target(), Source())
    let (t2, s2) = (Target(), Source())
    let (t3, s3) = (Target(), Source())
    let (t4, s4) = (Target(), Source())
    let (t5, s5) = (Target(), Source())
    let (t6, s6) = (Target(), Source())
    let (t7, s7) = (Target(), Source())
    let (t8, s8) = (Target(), Source())
    let (t9, s9) = (Target(), Source())
    let (t10, s10) = (Target(), Source())
    let (t11, s11) = (Target(), Source())
    let (t12, s12) = (Target(), Source())
    let (t13, s13) = (Target(), Source(sumWire))
    let (t14, s14) = (Target(), Source())
    let (t15, s15) = (Target(), Source())
    let (t16, s16) = (Target(), Source(carryWire))

    let inputs = [t1,t2,t3]
    let fork1 = Edge(FORK, [s1], [t4,t5])
    let fork2 = Edge(FORK, [s2], [t6,t7])
    let fork3 = Edge(FORK, [s3], [t8,t9])
    let xor1 = Edge(XOR, [s4,s6], [t10])
    let and1 = Edge(AND, [s7,s5], [t15])
    let fork4 = Edge(FORK, [s10], [t11,t12])
    let xor2 = Edge(XOR, [s11,s8], [t13])
    let and2 = Edge(AND, [s9,s12], [t14])
    let or = Edge(OR, [s14,s15], [t16])
    let edges = [fork1, fork2, fork3, xor1, and1, fork4, xor2, and2, or]
    let outputs = [s13,s16]

    let conns = [(t1,s1), (t2,s2), (t3,s3), (t4,s4), (t5,s5), (t6,s6), (t7,s7), (t8,s8), (t9,s9), (t10,s10), (t11,s11), (t12,s12), (t13,s13), (t14,s14), (t15,s15), (t16,s16)]    
    (ArrayList<Edge>(edges), ArrayList<Target>(inputs), ArrayList<Source>(outputs), ArrayList<Target * Source>(conns))
}

external func FullAdder(name!: String = "", sum!: String = "", cout!: String = "", bit!: Int64 = 0){
    Debug("FullAdder", "Making full adder; outputs sum='${sum}', cout='${cout}'")
    let (edges, inputs, outputs, conns) = FullAdderAtoms(sum: sum, cout: cout, bit: bit)
    Hypergraph(name, edges, inputs, outputs, PairListToMap(conns))
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
func AdderAtoms(width!: Int64, bit!: Int64 = 0, sum!: String = "", cout!: String = "") : ArrayList<Edge> * ArrayList<Target> * ArrayList<Target> * Target * ArrayList<Source> * ArrayList<Target * Source>{
    if(width < 1 || bit < 0){
         throw NotEnoughBitsException("Adder")
    }
    if(width == 1){
        let (edges, inputs, outputs, conns) = FullAdderAtoms(sum: sum, cout: cout, bit: bit)
        (edges, ArrayList<Target>([inputs[0]]), ArrayList<Target>([inputs[1]]), inputs[2], outputs, conns)
    } else {
        let n = width - 1
        
        let (hdEdges, hdInputs, hdOutputs, hdConns) = FullAdderAtoms(sum: sum, bit: bit)
        let (tlEdges, tlInputsL, tlInputsR, tlInputsC, tlOutputs, tlConns) = AdderAtoms(width: n, sum: sum, cout: cout, bit: bit + 1)

        let inputsL = ArrayList<Target>([hdInputs[0]])
        inputsL.addAll(tlInputsL)
        let inputsR = ArrayList<Target>([hdInputs[1]])
        inputsR.addAll(tlInputsR)
        let inputsC = hdInputs[2]
        let outputs = ArrayList<Source>([hdOutputs[0]])
        outputs.addAll(tlOutputs)

        let connL = hdConns.removeAt(15)
        let connR = tlConns.removeAt(2)
        hdConns.add((connL[0], connR[1]))


        hdEdges.addAll(tlEdges)
        hdConns.addAll(tlConns)

        (hdEdges, inputsL, inputsR, inputsC, outputs, hdConns)
    }
}

external func Adder(width!: Int64, sum!: String = "", cout!: String = "") {
    Debug("Adder", "Making n-bit adder of width ${width}, sum='${sum}', cout='${cout}'")
    let (edges, inputsL, inputsR, inputsC, outputs, conns) = AdderAtoms(width: width, bit: 0, sum: sum, cout: cout)
    inputsL.addAll(inputsR)
    inputsL.add(inputsC)
    Hypergraph(edges, inputsL, outputs, PairListToMap(conns))
}

external func Adder(width!: Int64, a!: Hypergraph, b!: Hypergraph, cin!: Hypergraph = Zero(width: 1), sum!: String = "", cout!: String = "", name!: String = "") : Hypergraph {
    Debug("Adder", "Making n-bit adder of width ${width}m with inputs a='${a.GetName()}', b='${b.GetName()}', cin='${cin.GetName()}'")
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
