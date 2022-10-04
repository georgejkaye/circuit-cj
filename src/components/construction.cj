/**
 * components/construction.cj
 *
 * Functions for constructing composite circuits that apply
 * smaller functions to multiple bits of wires in a variety of ways.
 *
 * @author George Kaye
 * @since 0.2
 */

package components

from std import collection.ArrayList

import debug.*

public enum Direction {
    | TOP_TO_BOTTOM
    | BOTTOM_TO_TOP
}


/**
 * Exception for users to throw if something is not implemented
 */
public class NotImplemented <: Exception {
    public init(msg : String) {
        ErrorMsg("Not implemented: ${msg}")
    }
}
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
 *                bits, the second is the control, and the third if the auxiliary
 * @return The output wire and the final aux value
 */
public func Bitwise<T, U, V, G>(
    ws : Array<T>,
    control : Array<U>,
    initial : Array<Wire<V, G>>,
    f : (Array<Wire<V, G>>, Array<U>, Array<Wire<V, G>>) -> (Array<Wire<V, G>>, Array<Wire<V, G>>),
    direction!: Direction = TOP_TO_BOTTOM
) : (Array<Wire<V, G>>, Array<Wire<V, G>>)
    where T <: ToString, T <: ContainsWire<V, G>, U <: ToString, U <: ContainsWire<V, G>,
            V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    let size = ws.size
    let width = AssertWiresSameWidth<T>(ws)
    // An array of arrays containing the wires of ws split explicitly into their
    // constituent bits: splitWires[i][j] is the jth bit of ws[i]
    let splitWires = Array<Array<Wire<V, G>>>(size, {
        i : Int64 =>
            let wire = ws[i].GetWire()
            Split(
                wire,
                Array<Int64>(width, { j : Int64 => 1 })
            )
    })
    // Set the auxiliary wires as the initial
    var aux = initial
    // For each bit of the primary inputs, apply the circuit function
    let outputs = ArrayList<Array<Wire<V, G>>>(width)
    for (i in 0..width) {
        let j = match(direction) {
            case TOP_TO_BOTTOM => i
            case BOTTOM_TO_TOP => width - 1 - i
        }
        // Get the ith bit of the jth input wire
        let inputs = Array<Wire<V, G>>(size, { k : Int64 => splitWires[k][j] })
        // Apply the function to transform this into output and a new aux
        let (output, carry) = f(inputs, control, aux)
        outputs.append(output)
        // Assign the new aux
        aux = carry
    }
    // Compress the individual bits back into thicker wires
    let outputWires = Array<Wire<V, G>>(
        outputs[0].size,
        { i : Int64 => Combine(Array<Wire<V, G>>(outputs.size, { j : Int64 => outputs[j][i] })) }
    )
    (outputWires, aux)
}
/**
 * Split multiple wires into their constituent bits, and perform some operation on each of them.
 * The operations will be applied from least significant bit to most significant bit. Additionally one
 * can provide an *auxiliary* array which is threaded between the operations (e.g. a carry).
 *
 * @param ws      The array of wires to input
 * @param initial The initial auxiliary array
 * @param f       The function to perform for the ith bit of each wire. The first argument is the input
 *                bits and the second is the auxiliary
 * @return The output wire and the final aux value
 */
public func Bitwise<T, V, G>(
    ws : Array<T>,
    initial : Array<Wire<V, G>>,
    f : (Array<Wire<V, G>>, Array<Wire<V, G>>) -> (Array<Wire<V, G>>, Array<Wire<V, G>>),
    direction!: Direction = TOP_TO_BOTTOM
) : (Array<Wire<V, G>>, Array<Wire<V, G>>)
    where T <: ToString, T <: ContainsWire<V, G>,
            V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G> {
    Bitwise<T, Wire<V, G>, V, G>(
        ws,
        Array<Wire<V, G>>(),
        initial,
        {ws : Array<Wire<V, G>>, ctl : Array<Wire<V, G>>, aux : Array<Wire<V, G>> => f(ws, aux)}
    )
}
/**
 * Split multiple wires into their constituent bits, and perform some operation on each of them.
 * The operations will be applied from least significant bit to most significant bit. Additionally one
 * can provide an *auxiliary* array which is threaded between the operations (e.g. a carry).
 *
 * @param ws      The array of wires to input
 * @param initial The initial auxiliary array
 * @param f       The function to perform for the ith bit of each wire. The first argument is the input
 *                bits and the second is the auxiliary
 * @return The output wire and the final aux value
 */
public func Bitwise<T, V, G>(
    ws : Array<T>,
    initial : Wire<V, G>,
    f : (Array<Wire<V, G>>, Wire<V, G>) -> (Wire<V, G>, Wire<V, G>),
    direction!: Direction = TOP_TO_BOTTOM
) : (Wire<V, G>, Wire<V, G>)
    where T <: ToString, T <: ContainsWire<V, G>,
            V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    let (finalOutput, finalAux) = Bitwise<T, Wire<V, G>, V, G>(
        ws,
        Array<Wire<V, G>>(),
        [initial],
        {ws : Array<Wire<V, G>>, ctl : Array<Wire<V, G>>, aux : Array<Wire<V, G>> =>
            let (currentOutput, currentAux) = f(ws, aux[0])
            ([currentOutput], [currentAux])
        },
        direction: direction
    )
    (finalOutput[0], finalAux[0])
}
/**
 * Split multiple wires into their constituent bits, and perform some operation on each of them.
 * The operations will be applied from least significant bit to most significant bit.
 *
 * @param ws      The array of wires to input
 * @param f       The function to perform for the ith bit of each wire
 * @return The output wire and the final aux value
 */
public func Bitwise<T, V, G>(
    ws : Array<T>,
    f : (Array<Wire<V, G>>) -> Array<Wire<V, G>>,
    direction!: Direction = TOP_TO_BOTTOM
) : Array<Wire<V, G>>
    where T <: ToString, T <: ContainsWire<V, G>,
        V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    Bitwise<T, Wire<V, G>, V, G>(
        ws,
        Array<Wire<V, G>>(),
        Array<Wire<V, G>>(),
        {ws : Array<Wire<V, G>>, ctl : Array<Wire<V, G>>, aux : Array<Wire<V, G>> => (f(ws), aux) },
        direction: direction,
    )[0]
}
/**
 * Split multiple wires into their constituent bits, and perform some operation on each of them.
 * The operations will be applied from least significant bit to most significant bit.
 *
 * @param ws      The array of wires to input
 * @param f       The function to perform for the ith bit of each wire
 * @return The output wire and the final aux value
 */
public func Bitwise<T, V, G>(
    ws : Array<T>,
    f : (Array<Wire<V, G>>) -> Wire<V, G>,
    direction!: Direction = TOP_TO_BOTTOM
) : Wire<V, G>
    where T <: ToString, T <: ContainsWire<V, G>,
            V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    Bitwise<T, Wire<V, G>, V, G>(
        ws,
        Array<Wire<V, G>>(),
        Array<Wire<V, G>>(),
        {ws : Array<Wire<V, G>>, ctl : Array<Wire<V, G>>, aux : Array<Wire<V, G>> => ([f(ws)], aux) },
        direction: direction
    )[0][0]
}
/**
 * Given a binary operation on wires that produces two outputs (intuitively an
 * 'output' and a 'carry'), 'ripple' it across an arbitrary number of input wires by
 * applying the gate to each input in turn combined with the carry of the previous application;
 * the outputs of each operation are then output at the end, along with the final carry.
 *
 * TODO: this and the below function could definitely be merged into
 * some general framework. Also there's lots of repeated code
 *
 * @param ws The array of input wires
 * @param f The binary operation (Wire<V, G>, Wire<V, G>) -> (Wire<V, G>, Wire<V, G>)
                on wires to compute
 *              The inputs to the function are (previous carry, current input)
 *              The outputs to the function are (current output, current carry)
 * @return The wires that carries the outputs of each operation
 */
public func Ripple<T, V, G>(
    ws : Array<T>,
    f : (Wire<V, G>, Wire<V, G>) -> (Wire<V, G>, Wire<V, G>),
    direction!: Direction = TOP_TO_BOTTOM
) : Array<Wire<V, G>> where
    T <: ToString, T <: ContainsWire<V, G>,
        V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    AssertMinNumberOfWires<T>(ws, 2)
    AssertWiresSameWidth<T>(ws)
    // The first gate is performed on inputs 0 and 1
    let outputs = ArrayList<Wire<V, G>>()
    let first = match(direction) {
        case TOP_TO_BOTTOM => 0
        case BOTTOM_TO_TOP => ws.size - 1
    }
    var prev = ws[first].GetWire()
    for (i in 1..ws.size) {
        let j = match(direction) {
            case TOP_TO_BOTTOM => i
            case BOTTOM_TO_TOP => ws.size - i - 1
        }
        // The second input to the gate is the next wire
        let cur = ws[j].GetWire()
        // Apply the gate to the previous carry and the current input
        let (currentOutput, currentCarry) = f(prev, cur)
        match(direction) {
            case TOP_TO_BOTTOM => outputs.append(currentOutput)
            case BOTTOM_TO_TOP => outputs.prepend(currentOutput)
        }
        prev = currentCarry
    }
    match(direction) {
        case TOP_TO_BOTTOM => outputs.append(prev)
        case BOTTOM_TO_TOP => outputs.prepend(prev)
    }
    outputs.toArray()
}
/**
 * Given a binary operation on wires that produces an output, 'ripple' it across an arbitrary
 * number of input wires by applying the gate to each input in turn combined with the output of
 * the previous application; the output of the final operation is then output at the end.
 *
 * @param ws The array of input wires
 * @param f The binary operation on wires to compute
 *              The inputs to the function are (previous carry, current input)
 *              The outputs to the function are (current output)
 * @return The wire that carries the output of the final ripple operation
 */
public func Ripple<T, V, G>(
    ws : Array<T>,
    f : (Wire<V, G>, Wire<V, G>) -> Wire<V, G>,
    direction!: Direction = TOP_TO_BOTTOM
) : Wire<V, G>
    where T <: ToString, T <: ContainsWire<V, G>,
        V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    AssertMinNumberOfWires<T>(ws, 2)
    AssertWiresSameWidth<T>(ws)
    // The first gate is performed on inputs 0 and 1
    let first = match(direction) {
        case TOP_TO_BOTTOM => 0
        case BOTTOM_TO_TOP => ws.size - 1
    }
    var prev = ws[first].GetWire()
    for (i in 1..ws.size) {
        let j = match(direction) {
            case TOP_TO_BOTTOM => i
            case BOTTOM_TO_TOP => ws.size - 1 - i
        }
        let cur = ws[j].GetWire()
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
public func InternalRipple<T, V, G>(
    w : T,
    f : (Wire<V, G>, Wire<V, G>) -> Wire<V, G>
) : Wire<V, G>
    where T <: ContainsWire<V, G>, T <: ToString,
            V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    AssertWireHasWidthAtLeast<T>(w, 2)
    let width = w.GetWidth()
    // Split the input wire into each bit
    let splitWires = Split<T, V, G>(
        w,
        Array<Int64>(width, { i : Int64 => 1 })
    )
    // Now this is just a ripple on eight inputs
    Ripple(splitWires, f)
}