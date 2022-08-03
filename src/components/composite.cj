package components

/**
 * Bitwise gates
 *
 * A bitwise gate is a generalisation of a logic gate for situations where the inputs
 * are of width greater than 1. Internally they are constructed as a copy of the gate
 * for each bit of the wire, applied in parallel.
 */

/**
 * Use a bitwise gate for a given primitive.
 * @param ws The input wires
 * @param prim The primitive to use in the bitwise gate
 */
public func UseBitwiseGate(ws : Array<Wire>, prim : Primitive) : Wire {
    UseSubcircuit(
        MakeBitwiseGate(
            prim,
            ws.size()
        ),
        ws
    )[0]
}


func PrimitiveToBitwiseFunction(prim : Primitive, w : Int64) : (Array<Wire>) -> Wire {
    AssertAtLeast(w, 1)
    if (w == 1) {
        prim.UseGate()
    } else {
        { ws : Array<Wire> =>
            match(prim) {
                case BUF  => Buf(ws[0])
                case NOT  => Not(ws[0])
                case AND  => And(ws[0], ws[1])
                case OR   => Or(ws[0], ws[1])
                case NAND => Nand(ws[0], ws[1])
                case NOR  => Nor(ws[0], ws[1])
                case XOR  => Xor(ws[0], ws[1])
                case XNOT => Xnor(ws[0], ws[1])
            }
        }
    }


}

/**
 * Ripple gates
 *
 * A ripple gate is a generalisation of binary logic gates for situations where there are
 * more than two inputs. Internally they are constructed as (n-1) gates for n inputs, where
 * the input of the ith gate is the output of the (i-1)th gate (or the 0th input wire if
 * is the first gate) and the (i+1)th input wire.
 */

public func UseRippleGate(ws : Array<Wire>, prim : Primitive) : Wire {
    AssertWireArrayNonEmpty(ws)
    let width = AssertWiresSameWidth(ws)
    UseSubcircuit_1<Wire>(
        MakeRippleGate(
            prim,
            ws.size(),
            width
        ),
        ws
    )
}

public func UseInternalRippleGate(w : Wire, prim : Primitive) : Wire {
    UseSubcircuit_1(
        MakeInternalRippleGate(
            prim,
            w.GetWidth()
        ),
        [w]
    )
}


