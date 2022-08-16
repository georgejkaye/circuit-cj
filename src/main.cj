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

    let sort = SortingNetwork(8, 4)
    WriteDotToFile(sort, 0, "sort-0")
    WriteDotToFile(sort, 1, "sort-1")
    WriteDotToFile(sort, 2, "sort-2")
    WriteDotToFile(sort, 3, "sort-3")

    return 0
}
