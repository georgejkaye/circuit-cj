from circuits import graphs.*
from circuits import syntax.*
from circuits import prelude.*
from circuits import settings.*
from circuits import components.*

from std import collection.ArrayList
from std import collection.HashSet

main(){

    SetDotDir("dot")
    SetDebugDot(true)

    let values = SignedValueFromInt(-72, 8)
    WriteDotToFile(values, "values")

    return 0
}