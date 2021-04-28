import hypergraphs.*
import examples.*

func main(){
    //let circ = HalfAdderCombinator()
    let circ = HalfAdderPorts()
    print(DotGraph(circ))
    //TestOps()
    return 0
}