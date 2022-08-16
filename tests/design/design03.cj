from circuits import graphs.WriteDotToFile
from circuits import examples.SimpleCPU

from circuits import settings.*

main(){

    SetDotDir("dot")

    let circ = SortingNetwork(8, 8)
    WriteDotToFile(circ, 0, "design02-01")
    WriteDotToFile(circ, 1, "design02-02")
    WriteDotToFile(circ, 2, "design02-03")
    WriteDotToFile(circ, 3, "design02-04")
    WriteDotToFile(circ, 4, "design02-05")

    return 0
}
