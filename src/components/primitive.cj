package components

import graphs.*
import syntax.*

func Gate(label : Label, inputs: Array<Wire>) : Wire {
    AssertAllWiresWidth(inputs, 1)
    AssertNumberOfWires(inputs, label.GetInputType().size())
    MakeEdge(label, inputs, [1])[0]
}

func NullaryGate(label : Label) : Wire {
    Gate(label, [])
}
func UnaryGate(label : Label, a : Wire) : Wire {
    Gate(label, [a])
}
func BinaryGate(label : Label, a : Wire, b : Wire) : Wire {
    Gate(label, [a,b])
}

/**
 * Nullary gates
 */
public func Signal(v : Value) : Wire {
    match(v) {
        case Bottom => BottomSignal()
        case False => FalseSignal()
        case True => TrueSignal()
        case Top => TopSignal()
    }
}
public func BottomSignal() : Wire {
    NullaryGate(BOTTOM)
}
public func FalseSignal() : Wire {
    NullaryGate(FALSE)
}
public func TrueSignal() : Wire {
    NullaryGate(TRUE)
}
public func TopSignal() : Wire {
    NullaryGate(TOP)
}

/**
 * Unary gates
 */

public func NotGate(a : Wire) : Wire {
    UnaryGate(NOT(1), a)
}

/**
 * Binary gates 
 */

public func AndGate(a : Wire, b : Wire) : Wire {
    BinaryGate(AND(2,1), a, b)
}
public func OrGate(a : Wire, b : Wire) : Wire {
    BinaryGate(OR(2,1), a, b)
}
public func NandGate(a : Wire, b : Wire) : Wire {
    BinaryGate(NAND(2,1), a, b)
}
public func NorGate(a : Wire, b : Wire) : Wire {
    BinaryGate(NOR(2,1), a, b)
}
public func XorGate(a : Wire, b : Wire) : Wire {
    BinaryGate(XOR(2,1), a, b)
}
public func XnorGate(a : Wire, b : Wire) : Wire {
    BinaryGate(XNOR(2,1), a, b)
}