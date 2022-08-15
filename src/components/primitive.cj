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
        [1],
        None
    )[0]
}
/**
 * Use a value generator
 *
 * @param spec The value spec to use
 * @return The output wire of the value
 */
func ValueGenerator(spec: ValueSpec) : Wire {
    MakeEdgeWithNewOutputs<Vertex, Int64>(
        VALUE(spec),
        Array<Vertex>(),
        [1],
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
    ValueGenerator(BOTTOM)
}
public func FalseSignal() : Wire {
    ValueGenerator(FALSE)
}
public func TrueSignal() : Wire {
    ValueGenerator(TRUE)
}
public func TopSignal() : Wire {
    ValueGenerator(TOP)
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
    BinaryGate(AND, a, b)
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
                    case BUF  => Buf(ws[0])
                    case NOT  => Not(ws[0])
                    case AND  => And(ws[0], ws[1])
                    case OR   => Or(ws[0], ws[1])
                    case NAND => Nand(ws[0], ws[1])
                    case NOR  => Nor(ws[0], ws[1])
                    case XOR  => Xor(ws[0], ws[1])
                    case XNOR => Xnor(ws[0], ws[1])
                }
        }
    }
}