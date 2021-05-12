import hypergraphs.*
import examples.*
import debug.*

func main(){
    // Info("Main", "Creating accumulator")
    // let acc = Accumulator(width: 2, initial: 0)
    // Info("Main", "Drawing graph")
    // WriteDotToFile(acc, "dot/acc.dot")
    // WriteDotToFile(ResolveLinks(acc), "dot/res.dot")

    let inputs = Input(width: 2, label: "in")
    let linkspec = LinkSpec("link", 2)
    let outlink = OutLink(spec: linkspec, input: inputs)
    let inlink1 = InLink(spec: linkspec)
    let inlink2 = InLink(spec: linkspec)
    let inl1 = inlink1[0]
    let inl2 = inlink2[1]
    let and = AndGate(lhs: inl1, rhs: inl2, output: "and")
    print("${and}\n")
    WriteDotToFile(and, "dot/and.dot")
    let x = outlink["in"]
    let y = Output([x, and])
    WriteDotToFile(y, "dot/test.dot")
    WriteDotToFile(ResolveLinks(y), "dot/res.dot")

    return 0
}