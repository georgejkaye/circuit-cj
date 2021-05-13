import hypergraphs.*
import examples.*
import debug.*

func main(){
    let runsum = running_sum_loop(first: True(), a: SignedValueFromInt(3, width:4), b0: True())
    WriteDotToFile(runsum, "dot/runsum.dot")
    return 0
}