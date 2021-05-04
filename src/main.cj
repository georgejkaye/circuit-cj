import hypergraphs.*
import examples.*

func main(){
    let circ = HalfAdderCombinator()
    //let circ = HalfAdderFunctional()
    WriteDotToFile(circ, "dot/main.dot")

    return 0
}
