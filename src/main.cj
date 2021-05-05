import hypergraphs.*
import examples.*
import library.*

func main(){

    let circ = Accumulator(2, 0)
    WriteDotToFile(circ, "dot/main.dot")

    return 0
}
