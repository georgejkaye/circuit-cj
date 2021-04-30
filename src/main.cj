import hypergraphs.*
import examples.*

func main(){
    //let circ = HalfAdderCombinator()
    let circ = HalfAdderPorts()
    let circ2 = circ.RemoveLeft(circ.GetOutputs()[0])
    print(DotGraph(circ2))
    //TestOps()
    return 0
}