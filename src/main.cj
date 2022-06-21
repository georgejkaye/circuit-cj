from circuits import settings.*
from circuits import syntax.*
from circuits import graphs.WriteDotToFile
from circuits import components.*
from circuits import examples.*

from std import collection.ArrayList
from std import collection.HashSet

main(){

    SetDotDir("dot")
    SetDebugDot(false)
    SetDotNumberRepresentation(DEC)

    let alu = ALU(2)
    WriteDotToFile(alu, "alu")

    return 0
}
