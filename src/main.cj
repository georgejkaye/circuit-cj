import hypergraphs.*
import examples.*
import debug.*

func main(){
    let runsum = serial_multiplier_bit(width: 4)
    WriteDotToFile(runsum, "dot/runsum.dot")
    return 0
}