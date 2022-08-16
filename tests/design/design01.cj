from circuits import graphs.WriteDotToFile
from circuits import examples.CyclicCombinational

from circuits import settings.*

main(){

    SetDotDir("dot")

    let circ = CyclicCombinational()
    WriteDotToFile(circ, 0, "comb")

    return 0
}
