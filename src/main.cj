from circuits import graphs.*
from circuits import syntax.*
from circuits import prelude.*
from circuits import settings.*
from circuits import components.*

from std import collection.ArrayList
from std import collection.HashSet

main(){

    SetDotDir("dot")
    SetDebugDot(false)
    SetDotNumberRepresentation(DEC)

    let vs = UnsignedValueFromInt(6, 4)

    let (split1, split2) = Split(vs, 3, 1)
    let not = NotGate(split2)
    let (split1a, split1b) = Split(split1, 2, 1)
    let (split1aa, split1ab) = Split(split1a, 1, 1)
    let and = AndGate(split1aa, split1ab)
    let comb1 = Combine(and, split1b)
    let comb2 = Combine(comb1, not)

    let circuit = MakeCircuit([], [comb2])
    WriteDotToFile(circuit, "values")

    return 0
}