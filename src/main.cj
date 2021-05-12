import hypergraphs.*
import examples.*
import debug.*

func main(){
    Info("Main", "Creating accumulator")
    let acc = Accumulator(width: 2, initial: 0)
    Info("Main", "Drawing graph")
    WriteDotToFile(acc, "dot/acc.dot")
    WriteDotToFile(ResolveLinks(acc), "dot/res.dot")

    // let inputs = Input(width: 2, label: "in")
    // let linkspec = LinkSpec("link", 2)
    // let outlink = OutLink(spec: linkspec, input: inputs)
    // let inlink1 = InLink(spec: linkspec)
    // let inlink2 = InLink(spec: linkspec)
    // let and = AndGate(lhs: inlink1[0], rhs: inlink2[1], output: "and")
    // let test = Output([and, outlink])
    // WriteDotToFile(test, "dot/test.dot")
    // WriteDotToFile(ResolveLinks(test), "dot/res.dot")

    return 0
}