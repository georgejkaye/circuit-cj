/**
 * components/primitive.cj
 *
 * Functions for manipulating primitives, the basic
 * logic gates that circuits are constructed from
 *
 * @author George Kaye
 * @since 0.2
 */

package components

import graphs.*
import syntax.*

/**
 * Use a primitive gate
 *
 * @param prim The primitive to apply
 * @param inputs The array of inputs
 * @return The output wire of the gate
 */
func Gate(prim : Primitive, inputs: Array<Wire>) : Wire {
    AssertAllWiresWidth(inputs, 1)
    AssertNumberOfWires(inputs, prim.GetInputPorts().size())
    MakeEdgeWithNewOutputs(
        PRIMITIVE(prim),
        inputs,
        None
    )[0]
}
/**
 * Use a value generator
 *
 * @param spec The value spec to use
 * @return The output wire of the value
 */
func ValueGenerator(v : Value) : Wire {
    MakeEdgeWithNewOutputs<Vertex>(
        VALUE(v),
        Array<Vertex>(),
        None<InterfacedHypergraph>
    )[0]
}
/**
 * Use a unary primitive gate
 *
 * @param prim The primitive to apply
 * @param a The input wire
 * @return The output wire of the gate
 */
func UnaryGate(prim : Primitive, a : Wire) : Wire {
    Gate(prim, [a])
}
/**
 * Use a binary primitive gate
 *
 * @param prim The primitive to apply
 * @param a The first input wire
 * @param a The second input wire
 * @return The output wire of the gate
 */
func BinaryGate(prim : Primitive, a : Wire, b : Wire) : Wire {
    Gate(prim, [a,b])
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
    ValueGenerator(Bottom)
}
public func FalseSignal() : Wire {
    ValueGenerator(False)
}
public func TrueSignal() : Wire {
    let w = ValueGenerator(True)
    w
}
public func TopSignal() : Wire {
    ValueGenerator(Top)
}

/**
 * Unary gates
 */

public func BufGate(a : Wire) : Wire {
    UnaryGate(BUF, a)
}
public func NotGate(a : Wire) : Wire {
    UnaryGate(NOT, a)
}

/**
 * Binary gates
 */

public func AndGate(a : Wire, b : Wire) : Wire {
    let w = BinaryGate(AND, a, b)
    w
}
public func OrGate(a : Wire, b : Wire) : Wire {
    BinaryGate(OR, a, b)
}
public func NandGate(a : Wire, b : Wire) : Wire {
    BinaryGate(NAND, a, b)
}
public func NorGate(a : Wire, b : Wire) : Wire {
    BinaryGate(NOR, a, b)
}
public func XorGate(a : Wire, b : Wire) : Wire {
    BinaryGate(XOR, a, b)
}
public func XnorGate(a : Wire, b : Wire) : Wire {
    BinaryGate(XNOR, a, b)
}

extend Primitive {
    func UseGate() : (Array<Wire>) -> Wire {
        {
            ws : Array<Wire> =>
                match(this) {
                    case BUF  => BufGate(ws[0])
                    case NOT  => NotGate(ws[0])
                    case AND  => AndGate(ws[0], ws[1])
                    case OR   => OrGate(ws[0], ws[1])
                    case NAND => NandGate(ws[0], ws[1])
                    case NOR  => NorGate(ws[0], ws[1])
                    case XOR  => XorGate(ws[0], ws[1])
                    case XNOR => XnorGate(ws[0], ws[1])
                }
        }
    }
}