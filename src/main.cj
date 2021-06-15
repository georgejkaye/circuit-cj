import circuits.*
import examples.*
import debug.*
import settings.*

func main(){

    SetDotDir("dot")
    
    let wf = WaveformFromList([3,2,6], width: 4)
    WriteDotToFile(wf, "wf")

    let circ = wf + Accumulator(width: 4, initial: 1)
    WriteDotToFile(circ, "circ")
    let rewriter = circ.GetRewriter()
    rewriter.RunCycle()
    WriteDotToFile(rewriter.GetGraph(), "cycle1")
    rewriter.RunCycle()
    WriteDotToFile(rewriter.GetGraph(), "cycle2")

    return 0
}