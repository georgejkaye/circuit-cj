import hypergraphs.*
import examples.*

func main(){
    let circ = HalfAdderCombinator()
    //let circ = HalfAdderPorts()
    //let circ2 = RemoveLeft(circ, circ.GetOutputs()[0])
    print(DotGraph(circ))
    //TestOps()
    return 0
}