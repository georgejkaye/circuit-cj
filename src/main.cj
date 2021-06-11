import circuits.*
import examples.*
import debug.*
import settings.*

func main(){

    SetDotDir("dot")
    
    let wf = WaveformFromList([3,2,6], width: 3)
    WriteDotToFile(wf, "wf")

    //let circ = (True() * Delay(dur: 1) + Join()) * True() + XorGate()
    /*let circ = UnsignedValueFromInt(2, width: 2) + Accumulator(width: 2, initial: 1)
    WriteDotToFile(circ, "circ")
    let rewriter = circ.GetRewriter()
    rewriter.RunLocal()
    WriteDotToFile(rewriter.GetGraph(), "local")
    rewriter.RunCycle()
    WriteDotToFile(rewriter.GetGraph(), "cycle1")*/

    return 0
}