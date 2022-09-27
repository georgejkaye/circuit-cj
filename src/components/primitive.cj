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
func UseOperation(label : Label, inputs: Array<Wire>) : Wire {
    AssertNumberOfWires(inputs, label.GetInputPorts().size())
    UseEdgeWithNewOutputs(
        label,
        inputs,
        None
    )[0]
}
/**
 * Use a primitive gate
 *
 * @param prim The primitive to apply
 * @param inputs The input wires
 */
func UseGate(prim : Primitive, inputs : Array<Wire>) : Wire {
    AssertAllWiresWidth(inputs, 1)
    UseOperation(PRIMITIVE(prim), inputs)
}
/**
 * Use a unary primitive gate
 *
 * @param prim The primitive to apply
 * @param a The input wire
 * @return The output wire of the gate
 */
func UseUnaryGate(prim : Primitive, a : Wire) : Wire {
    UseGate(prim, [a])
}
/**
 * Use a binary primitive gate
 *
 * @param prim The primitive to apply
 * @param a The first input wire
 * @param a The second input wire
 * @return The output wire of the gate
 */
func UseBinaryGate(prim : Primitive, a : Wire, b : Wire) : Wire {
    UseGate(prim, [a,b])
}

/**
 * Nullary gates
 */

public func UseValue(v : Value) : Wire {
    UseEdgeWithNewOutputs<Vertex>(
        VALUE(v),
        Array<Vertex>(),
        None<InterfacedHypergraph>
    )[0]
}

/**
 * Unary gates
 */

public func BufGate(a : Wire) : Wire {
    UseUnaryGate(BUF, a)
}
public func NotGate(a : Wire) : Wire {
    UseUnaryGate(NOT, a)
}

/**
 * Binary gates
 */

public func AndGate(a : Wire, b : Wire) : Wire {
    UseBinaryGate(AND, a, b)
}
public func OrGate(a : Wire, b : Wire) : Wire {
    UseBinaryGate(OR, a, b)
}
public func NandGate(a : Wire, b : Wire) : Wire {
    UseBinaryGate(NAND, a, b)
}
public func NorGate(a : Wire, b : Wire) : Wire {
    UseBinaryGate(NOR, a, b)
}
public func XorGate(a : Wire, b : Wire) : Wire {
    UseBinaryGate(XOR, a, b)
}
public func XnorGate(a : Wire, b : Wire) : Wire {
    UseBinaryGate(XNOR, a, b)
}
public func Join(a : Wire, b : Wire) : Wire {
    UseOperation(JOIN(a.GetWidth()), [a, b])
}

extend Primitive {
    func UseGate() : (Array<Wire>) -> Wire {
        {
            ws : Array<Wire> =>
                match(this.GetName()) {
                    case "BUF"  => BufGate(ws[0])
                    case "NOT"  => NotGate(ws[0])
                    case "AND"  => AndGate(ws[0], ws[1])
                    case "OR"   => OrGate(ws[0], ws[1])
                    case "NAND" => NandGate(ws[0], ws[1])
                    case "NOR"  => NorGate(ws[0], ws[1])
                    case "XOR"  => XorGate(ws[0], ws[1])
                    case "XNOR" => XnorGate(ws[0], ws[1])
                    case s => throw NotImplemented("The primitive ${s} has not been implemented")
                }
        }
    }
}