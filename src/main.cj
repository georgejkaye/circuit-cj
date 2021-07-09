import circuits.*
import examples.*
import debug.*
import settings.*

func main(){

    SetDotDir("dot")
    
    let wf = WaveformFromList([3,2], width: 3)
    WriteDotToFile(wf, "wf")
    let circ = Accumulator(width: 3, initial: 1)
    WriteDotToFile(circ, "circ")
    let applied = wf + circ
    WriteDotToFile(applied, "applied")
    let rewriter = circ.GetRewriter()
    rewriter.RunCycle()
    WriteDotToFile(rewriter.GetGraph(), "cycle1")
    rewriter.RunCycle()
    WriteDotToFile(rewriter.GetGraph(), "cycle2")

    return 0
}