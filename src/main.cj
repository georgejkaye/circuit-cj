from circuits import graphs.Traverse
from circuits import graphs.WriteDotToFile
from circuits import examples.Accumulator

from circuits import settings.*
from circuits import graphs.Edge

from circuits import examples.ALU

main(){

    SetDotDir("dot")
    SetNumberRepresentation(DEC)
    SetDebugDot(true)

    let circ = ALU(8)
    WriteDotToFile(circ, 0, "alu")
    WriteDotToFile(circ, 1, "alu-expanded")

    let edges = circ.GetEdges()
    var i = 0
    var edge = None<Edge>
    for(e in edges) {
        if (i == 0){
            edge = Some(e)
            i++
        }
    }
    match(edge) {
        case None => ()
        case Some(e) =>
            println("bursting ${e}")
            e.BurstSubgraph()
            WriteDotToFile(circ, 0, "alu-${i}")
    }

    return 0
}
