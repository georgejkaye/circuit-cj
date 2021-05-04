import hypergraphs.*
import examples.*
import library.*

func main(){

    let circ = Accumulator(10)
    WriteDotToFile(circ, "dot/main.dot")

    return 0
}
