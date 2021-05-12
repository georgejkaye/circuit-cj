import hypergraphs.*
import examples.*
import debug.*

func main(){
    Info("Main", "Creating accumulator")
    let acc = Accumulator(width: 2, initial: 0)
    Info("Main", "Drawing graph")
    WriteDotToFile(acc, "dot/acc.dot")
    WriteDotToFile(ResolveLinks(acc), "dot/res.dot")

    return 0
}