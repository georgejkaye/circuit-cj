package components

import graphs.*

/**
 * Split multiple wires into their constituent bits, and perform some operation on each of them.
 * The operations will be applied from least significant bit to most significant bit. Additionally one
 * can provide a *control* array that is copied between each gate application (e.g. the sel input to a mux),
 * and an *auxiliary* array which is threaded between the operations (e.g. a carry)
 *
 * @param ws      The array of wires to input
 * @param control The control array
 * @param initial The initial auxiliary array
 * @param f       The function to perform for the ith bit of each wire. The first argument is the input
 *                  bits, the second is the control, and the third if the auxiliary
 * @return The output wire and the final aux value
 */
public func Bitwise<T, U>(
    ws : Array<T>,
    control : Array<U>,
    initial : Array<Wire>,
    f : (Array<Wire>, Array<U>, Array<Wire>) -> (Array<Wire>, Array<Wire>)
) : (Array<Wire>, Array<Wire>) where T <: ToString, T <: ContainsWire, U <: ToString, T <: ContainsWire {
    let size = ws.size()
    let width = AssertWiresSameWidth<T>(ws)
    // An array of arrays containing the wires of ws split explicitly into their
    // constituent bits: splitWires[i][j] is the jth bit of ws[i]
    let splitWires = Array<Array<Wire>>(size) {
        i : Int64 =>
            let wire = ws[i].GetWire()
            Split(
                wire,
                Array<Int64>(width){ j : Int64 => 1}
            )
    }
    // Set the auxiliary wires as the initial
    var aux = initial
    // For each bit of the primary inputs, apply the circuit function
    let outputs = ArrayList<Array<Wire>>(width)
    for (i in 0..width) {
        // Get the ith bit of the jth input wire
        let inputs = Array<Wire>(size){ j : Int64 => splitWires[j][i] }
        // Apply the function to transform this into output and a new aux
        let (output, carry) = f(inputs, control, aux)
        outputs.append(output)
        // Assign the new aux
        aux = carry
    }
    // Compress the individual bits back into thicker wires
    let outputWires = Array<Wire>(outputs.size()){
        i : Int64 =>
            Combine(outputs[i])
    }
    (outputWires, aux)
}
/**
 * Split multiple wires into their constituent bits, and perform some operation on each of them.
 * The operations will be applied from least significant bit to most significant bit.
 *
 * @param ws      The array of wires to input
 * @param f       The function to perform for the ith bit of each wire
 * @return The output wire and the final aux value
 */
public func Bitwise<T>(
    ws : Array<T>,
    f : (Array<Wire>) -> Array<Wire>
) : Array<Wire> where T <: ToString, T <: ContainsWire {
    Bitwise<T, Wire>(
        ws,
        Array<Wire>(),
        Array<Wire>(),
        {ws : Array<Wire>, ctl : Array<Wire>, aux : Array<Wire> => (f(ws), aux) }
    )[0]
}
/**
 * Given a binary operation on wires, 'ripple' it across an arbitrary
 * number of input wires by applying the gate to each input in turn combined
 * with the result of the previous application
 *
 * @param ws The array of input wires
 * @param f The binary operation on wires to compute
 * @return The wire that carries the data of the complete ripple operation
 */
public func Ripple<T>(
    ws : Array<T>,
    f : (Wire, Wire) -> (Wire)
) : Wire where T <: ToString, T <: ContainsWire {
    AssertMinNumberOfWires<T>(ws, 2)
    let width = AssertWiresSameWidth<T>(ws)
    let size = ws.size()
    // The first gate is performed on inputs 0 and 1
    var prev = ws[0].GetWire()
    for (i in 1..size) {
        // The second input to the gate is the next wire
        let cur = ws[i].GetWire()
        // Apply the gate to the previous output and the current input
        prev = f(prev, cur)
    }
    prev
}
/**
 * Given a binary operation on wires, 'ripple' it across an arbitrary width wire
 * by applying the gate to each bit in turn combined with the result of the previous application
 *
 * @param w The input wire
 * @param f The binary operation on wires to compute
 * @return The wire that carries the data of the complete ripple operation
 */
public func InternalRipple<T>(
    w : T,
    f : (Wire, Wire) -> (Wire)
) : Wire where T <: ContainsWire, T <: ToString {
    AssertWireHasWidthAtLeast<T>(w, 2)
    let width = w.GetWidth()
    // Split the input wire into each bit
    let splitWires = Split<T>(
        w,
        Array<Int64>(width){ i : Int64 => 1 }
    )
    // Now this is just a ripple on eight inputs
    Ripple(splitWires, f)
}