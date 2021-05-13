import hypergraphs.*
import examples.*
import debug.*

func main(){
    // Info("Main", "Creating accumulator")
    // let acc = Accumulator(width: 2, initial: 0)
    // Info("Main", "Drawing graph")
    // WriteDotToFile(acc, "dot/acc.dot")
    // WriteDotToFile(ResolveLinks(acc), "dot/res.dot")

    let inputs = Input(width: 4, label: "input")
    let ls = LinkSpec("link", 4)
    let outlink = OutLink(spec: ls, input: inputs)
    let in1 = InLink(spec: ls)
    let in2 = InLink(spec: ls)
    let and1 = AndGate(lhs: in1[0], rhs: in2[0])
    let and2 = AndGate(lhs: in1[1], rhs: in2[1])
    let and3 = AndGate(lhs: in1[2], rhs: in2[2])
    let and4 = AndGate(lhs: in1[3], rhs: in2[3])
    let c = Output([and1,and2,and3,and4,outlink])
    WriteDotToFile(c, "dot/c.dot")

    return 0
}