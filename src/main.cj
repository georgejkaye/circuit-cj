import hypergraphs.*
import examples.*

func main(){
    //let circ = HalfAdderCombinator()
    let circ = HalfAdderFunctional()
    print(DotGraph(circ))
    return 0
}