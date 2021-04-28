import hypergraphs.*
import examples.HalfAdderCombinator

func main(){
    let circ = HalfAdderCombinator()
    print(DotGraph(circ))
    return 0
}