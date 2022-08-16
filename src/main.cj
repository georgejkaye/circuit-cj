from circuits import graphs.WriteDotToFile
from circuits import examples.SimpleCPU

from circuits import settings.*

main(){

    SetDotDir("dot")

    let circ = SimpleCPU()
    WriteDotToFile(circ, 0, "design03-01")
    WriteDotToFile(circ, 1, "design03-02")
    WriteDotToFile(circ, 2, "design03-03")
    WriteDotToFile(circ, 3, "design03-04")
    WriteDotToFile(circ, 4, "design03-05")

    return 0
}
