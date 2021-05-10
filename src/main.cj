import hypergraphs.*
import examples.*
import debug.*

func main(){
    Info("Main", "Creating accumulator")
    let acc = Accumulator(width: 2, initial: 1)
    print("${acc}")
    Info("Main", "Drawing graph")
    WriteDotToFile(acc, "dot/main.dot")
    return 0
}