/**
 * This file contains constant circuits that can be defined directly as hypergraphs
 * This is more efficient (although less elegant) than defining them by combining other constructs
 */

package hypergraphs

import debug.*

external func HalfAdder(sum!: String = "", carry!: String = "", bit!: Int64 = 0, name!: String = "") : Hypergraph {
    Debug("Half adder", "Making half adder, sum='${sum}', carry='${carry}'")
    
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

    Hypergraph(name, edges, inputs, outputs, conns.toMap())
}

external func HalfAdder(a!: Hypergraph, b!: Hypergraph, sum!: String = "", carry!: String = "", bit!: Int64 = 0, name!: String = "") : Hypergraph {
    if(a.GetN() != 1){
        throw BadInputException("HalfAdder", "a", 1, a.GetName(), a.GetN())
    }
    if(b.GetN() != 1){
        throw BadInputException("HalfAdder", "b", 1, b.GetName(), b.GetN())
    }
    Seq(Output([a,b]), HalfAdder(sum: sum, carry: carry, bit: bit), name: name)
}

external func FullAdder(sum!: String = "", cout!: String = "", bit!: Int64 = 0, name!: String = "") : Hypergraph {
    Debug("Full adder", "Making full adder, sum='${sum}', cout='${cout}'")
    if(bit < 0){
        throw NotEnoughBitsException("FullAdder")
    }
    
    let sumWire = NewWire(sum, bit)
    let carryWire = NewWire(cout, bit)

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
    let (t13, s13) = (Target(), Source())
    let (t14, s14) = (Target(), Source())
    let (t15, s15) = (Target(), Source(sumWire))
    let (t16, s16) = (Target(), Source(carryWire))

    let inputs = [t1,t2,t3]
    let fork1 = Edge(FORK, [s1], [t4,t5])
    let fork2 = Edge(FORK, [s2], [t6,t7])
    let fork3 = Edge(FORK, [s3], [t8,t9])
    let xor1 = Edge(XOR, [s4,s6], [t10])
    let and1 = Edge(AND, [s5,s7], [t15])
    let fork4 = Edge(FORK, [s10], [t11,t12])
    let xor2 = Edge(XOR, [s11,s8], [t13])
    let and2 = Edge(AND, [s12,s9], [t14])
    let or = Edge(OR, [s14,s15], [t16])
    let edges = [fork1, fork2, fork3, xor1, and1, fork4, xor2, and2, or]
    let outputs = [s13,s16]

    let conns = MapBuilder<Target,Source>()
    conns.add(t1,s1)
    conns.add(t2,s2)
    conns.add(t3,s3)
    conns.add(t4,s4)
    conns.add(t5,s5)
    conns.add(t6,s6)
    conns.add(t7,s7)
    conns.add(t8,s8)
    conns.add(t9,s9)
    conns.add(t10,s10)
    conns.add(t11,s11)
    conns.add(t12,s12)
    conns.add(t13,s13)
    conns.add(t14,s14)
    conns.add(t15,s15)
    conns.add(t16,s16)
    
    Hypergraph(name, edges, inputs, outputs, conns.toMap())

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