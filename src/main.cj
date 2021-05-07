import hypergraphs.*
import examples.*

func main(){
    let acc = Accumulator(width: 2, initial: 1)
    WriteDotToFile(acc, "dot/main.dot")
    return 0
}