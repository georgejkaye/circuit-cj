import hypergraphs.*
import examples.*
import library.*

func main(){

    let circ = Accumulator(4, 0)
    WriteDotToFile(circ, "dot/main.dot")

    //let a = AndGate(output: "and")
    //let b = Identity(1)
    //let c = Seq(a,b)
    //WriteDotToFile(c, "dot/seq.dot")

    return 0
}
