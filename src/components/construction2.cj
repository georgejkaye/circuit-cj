package components

from std import collection.ArrayList

import debug.*

public class NotImplemented <: Exception {
    public init(msg : String) {
        ErrorMsg("Not implemented: ${msg}")
    }
}

public enum Direction {
    | TOP_TO_BOTTOM
    | BOTTOM_TO_TOP
}
/**
 * Given a function that transforms arrays of wires into a single wire,
 * generalise it so that it produces an array of wires instead, by wrapping the outputs
 * into an array
 *
 * @param f The function to generalise
 * @return The generalised function
 */
func GeneraliseSingleOutputFunction<V, G>(
    f : (Array<Wire<V, G>>) -> Wire<V, G>
) : (Array<Wire<V, G>>) -> Array<Wire<V, G>>
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    { ws : Array<Wire<V, G>> => [f(ws)] }
}
/**
 * Given an array of arrays of wires, which are assumed to each contain one element,
 * flatten it into an array of wires, where each element is the zeroth element of the
 * original array elements.
 *
 * @param wss The array of arrays of wires
 * @return The flattened array
 */
func FlattenSingleWireOutputs<V, G>(
    wss : Array<Array<Wire<V, G>>>
) : Array<Wire<V, G>>
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    map({ ws : Array<Wire<V, G>> => ws[0] }, wss)
}
/**
 * Given an array of arrays of wires, apply an operation that transforms an array
 * of wires into a new array of wires, to each array of wires in the input.
 *
 * @param f The operation to apply
 * @param wss The array of arrays of wires
 * @return The output array of arrays of wires
 */
public func Map<V, G>(
    f : (Array<Wire<V, G>>) -> Array<Wire<V, G>>,
    wss : Array<Array<Wire<V, G>>>
) : Array<Array<Wire<V, G>>>
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    let width = AssertWireArrayArraysCompatible(wss)
    map({ws : Array<Wire<V, G>> => f(ws)}, wss)
}
/**
 * Given an array of arrays of wires, apply an operation that transforms an array
 * of wires into a new wire, to each array of wires in the input.
 *
 * @param f The operation to apply
 * @param wss The array of arrays of wires
 * @return The output array of wires
 */
public func Map<V, G>(
    f : (Array<Wire<V, G>>) -> Wire<V, G>,
    wss : Array<Array<Wire<V, G>>>
) : Array<Wire<V, G>>
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    let outputWires = Map(GeneraliseSingleOutputFunction(f), wss)
    FlattenSingleWireOutputs(outputWires)
}
/**
 * Given an array of wires, split them to create an array of arrays of one-bit wires,
 * of the form [[w0[0], w1[0], ...], [w0[1], w1[1], ...], ...].
 *
 * @param ws The array of wires to split
 * @return The array of arrays of split wires
 */
public func BitwiseSplit<V, G>(
    ws : Array<Wire<V, G>>
) : Array<Array<Wire<V, G>>>
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    let width = AssertWiresSameWidth(ws)
    let splitInputs = map({ w : Wire<V, G> => Split(w) }, ws)
    Array<Array<Wire<V, G>>>(width){ i : Int64 =>
        Array<Wire<V, G>>(ws.size){ j : Int64 => splitInputs[j][i] }
    }
}
/**
 * Given an array of arrays of wires, combine them to create an array of wires, so that
 * w[0] = {wss[0][0], wss[1][0], ...}, ws[1] = {wss[1][0], wss[1][1], ...}, ...
 *
 * @param wss The array of arrays of wires to combine
 * @return The array of combined wires
 */
public func BitwiseCombine<V, G>(
    wss : Array<Array<Wire<V, G>>>
) : Array<Wire<V, G>>
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    let size = AssertWireArrayArraysCompatible(wss)
    Array<Wire<V, G>>(size){
        i : Int64 => Combine(Array<Wire<V, G>>(wss.size){
            j : Int64 => wss[j][i]
        })
    }
}
/**
 * Given an array of wires, apply an operation that transforms an array of wires
 * into an array of wires to each set of corresponding bits in parallel
 *
 * @param f The function to apply to each set of corresponding bits
 * @param ws The array of wires
 * @return The result of the computation
 */
public func BitwiseMap<V, G>(
    f : (Array<Wire<V, G>>) -> Array<Wire<V, G>>,
    ws : Array<Wire<V, G>>
) : Array<Wire<V, G>>
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    let inputWires = BitwiseSplit(ws)
    let outputWires = Map(f, inputWires)
    BitwiseCombine(outputWires)
}
/**
 * Given an array of wires, apply an operation that transforms an array of wires
 * into a single wire to each set of corresponding bits in parallel
 *
 * @param f The function to apply to each set of corresponding bits
 * @param ws The array of wires
 * @return The result of the computation
 */
public func BitwiseMap<V, G>(
    f : (Array<Wire<V, G>>) -> Wire<V, G>,
    ws : Array<Wire<V, G>>
) : Wire<V, G>
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    BitwiseMap(GeneraliseSingleOutputFunction(f), ws)[0]
}
/**
 * Given an array of wires (initial) and an array of arrays of wires (inputs), apply an operation
 * that takes an accumulator and input and produces an output and a new accumulator in turn to
 * each input, with the accumulator originally set as the initial array.
 *
 * @param f The operation to ripple
 * @param initial The initial array to set as the accumulator
 * @param wss The array of inputs
 * @param direction The direction to ripple
 * @param The list of outputs and the final accumulator
 */
public func RippleMap<V, G>(
    f : (Array<Wire<V, G>>, Array<Wire<V, G>>) -> (Array<Wire<V, G>>, Array<Wire<V, G>>),
    initial : Array<Wire<V, G>>,
    wss : Array<Array<Wire<V, G>>>,
    direction!: Direction = TOP_TO_BOTTOM
) : (Array<Array<Wire<V, G>>>, Array<Wire<V, G>>)
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    let width = AssertWireArrayArraysCompatible(wss)
    var acc = initial
    let outputs = ArrayList<Array<Wire<V, G>>>()
    for(i in 0..wss.size) {
        let j = match(direction) {
            case TOP_TO_BOTTOM => i
            case BOTTOM_TO_TOP => wss.size - 1 - i
        }
        let cur = wss[j]
        let (curRes, curAcc) = f(acc, cur)
        match(direction) {
            case TOP_TO_BOTTOM => outputs.append(curRes)
            case BOTTOM_TO_TOP => outputs.prepend(curRes)
        }
        acc = curAcc
    }
    (outputs.toArray(), acc)
}
/**
 * Given an array of wires (initial) and an array of arrays of wires (inputs), apply an operation
 * that takes an accumulator and input and produces an output and a new accumulator in turn to
 * each input, with the accumulator originally set as the initial array.
 *
 * @param f The operation to ripple
 * @param initial The initial array to set as the accumulator
 * @param wss The array of inputs
 * @param direction The direction to ripple
 * @return The array of outputs and the final accumulator
 */
public func RippleMap<V, G>(
    f : (Wire<V, G>, Array<Wire<V, G>>) -> (Wire<V, G>, Wire<V, G>),
    initial : Wire<V, G>,
    wss : Array<Array<Wire<V, G>>>,
    direction!: Direction = TOP_TO_BOTTOM
) : (Array<Wire<V, G>>, Wire<V, G>)
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    let (outputs, acc) = RippleMap(
        { acc : Array<Wire<V, G>>, cur : Array<Wire<V, G>> =>
            let (curOutput, curAcc) = f(acc[0], cur)
            ([curOutput], [curAcc])
        },
        [initial],
        wss,
        direction: direction
    )
    (FlattenSingleWireOutputs(outputs), acc[0])
}
/**
 * Given an array of arrays of wires, set the first array as an initial array, then apply an operation
 * that takes an accumulator and input and produces an output and a new accumulator in turn to
 * each input, with the accumulator originally set as the initial array.
 *
 * @param f The operation to ripple
 * @param initial The initial array to set as the accumulator
 * @param wss The array of inputs
 * @param direction The direction to ripple
 * @return The array of outputs and the final accumulator
 */
public func RippleMap<V, G>(
    f : (Array<Wire<V, G>>, Array<Wire<V, G>>) -> (Array<Wire<V, G>>, Array<Wire<V, G>>),
    wss : Array<Array<Wire<V, G>>>,
    direction!: Direction = TOP_TO_BOTTOM
) : (Array<Array<Wire<V, G>>>, Array<Wire<V, G>>)
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    let (initial, rest) = GetFirstAndRest(wss)
    RippleMap(f, initial, rest, direction: direction)
}
/**
 * Given an array of wires, set the first wire as an initial wire, then apply an operation
 * that takes an accumulator and input and produces an output and a new accumulator in turn to
 * each input, with the accumulator originally set as the initial wire.
 *
 * @param f The operation to ripple
 * @param initial The initial array to set as the accumulator
 * @param wss The array of inputs
 * @param direction The direction to ripple
 * @return The array of outputs and the final accumulator
 */
public func RippleMap<V, G>(
    f : (Wire<V, G>, Wire<V, G>) -> (Wire<V, G>, Wire<V, G>),
    ws : Array<Wire<V, G>>,
    direction!: Direction = TOP_TO_BOTTOM
) : (Array<Wire<V, G>>, Wire<V, G>)
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    let (outputs, acc) = RippleMap<V, G>(
        { acc : Array<Wire<V, G>>, cur : Array<Wire<V, G>> =>
            let (curRes, curAcc) = f(acc[0], cur[0])
            ([curRes], [curAcc])
        },
        map({ w : Wire<V, G> => [w] }, ws),
        direction: direction
    )
    (FlattenSingleWireOutputs(outputs), acc[0])
}
/**
 * Given an array of wires (initial) and an array of arrays of wires (inputs), apply an operation
 * that takes an accumulator and input and produces a new accumulator in turn to
 * each input, with the accumulator originally set as the initial array.
 *
 * @param f The operation to ripple
 * @param initial The initial array to set as the accumulator
 * @param wss The array of inputs
 * @param direction The direction to ripple
 * @return The final accumulator
 */
public func Ripple<V, G>(
    f : (Array<Wire<V, G>>, Array<Wire<V, G>>) -> Array<Wire<V, G>>,
    initial : Array<Wire<V, G>>,
    wss : Array<Array<Wire<V, G>>>,
    direction!: Direction = TOP_TO_BOTTOM
) : Array<Wire<V, G>>
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    let (_, acc) = RippleMap(
        { acc : Array<Wire<V, G>>, cur : Array<Wire<V, G>> =>
            let curAcc = f(acc, cur)
            ([], curAcc)
        },
        initial,
        wss,
        direction: direction
    )
    acc
}
/**
 * Given an array of wires (initial) and an array of arrays of wires (inputs), apply an operation
 * that takes an accumulator and input and produces an output and a new accumulator in turn to
 * each input, with the accumulator originally set as the initial array.
 *
 * @param f The operation to ripple
 * @param initial The initial array to set as the accumulator
 * @param wss The array of inputs
 * @param direction The direction to ripple
 * @param The list of outputs and the final accumulator
 */
public func Ripple<V, G>(
    f : (Wire<V, G>, Array<Wire<V, G>>) -> Wire<V, G>,
    initial : Wire<V, G>,
    wss : Array<Array<Wire<V, G>>>,
    direction!: Direction = TOP_TO_BOTTOM
) : Wire<V, G>
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    Ripple(
        { acc : Array<Wire<V, G>>, cur : Array<Wire<V, G>> =>
            let curAcc = f(acc[0], cur)
            [curAcc]
        },
        [initial],
        wss,
        direction: direction
    )[0]
}
/**
 * Given an array, split it into the first element and an array of the remaining elements
 *
 * @param xs The array
 * @return The first element and the rest
 */
func GetFirstAndRest<T>(xs : Array<T>) : (T, Array<T>) where T <: ToString {
    AssertArrayHasMinimumLength(xs, 1)
    let first = xs[0]
    let rest = if(xs.size == 1) {
        Array<T>()
    } else {
        Array<T>(xs.size - 1){
            i : Int64 => xs[i+1]
        }
    }
    (first, rest)
}
/**
 * Given ann array of arrays of wires (inputs), set the first array as the initial array, and apply an
 * operation that takes an accumulator and input and produces an output and a new accumulator in turn to
 * each input, with the accumulator originally set as the initial array.
 *
 * @param f The operation to ripple
 * @param wss The array of inputs
 * @param direction The direction to ripple
 * @return The array of outputs and the final accumulator
 */
public func Ripple<V, G>(
    f : (Array<Wire<V, G>>, Array<Wire<V, G>>) -> Array<Wire<V, G>>,
    wss : Array<Array<Wire<V, G>>>,
    direction!: Direction = TOP_TO_BOTTOM
) : Array<Wire<V, G>>
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    let (initial, rest) = GetFirstAndRest(wss)
    Ripple(f, initial, rest, direction: direction)
}
/**
 * Given ann array of wires (inputs), set the first wire as the initial wire, and apply an
 * operation that takes an accumulator and input and produces an output and a new accumulator in turn to
 * each input, with the accumulator originally set as the initial array.
 *
 * @param f The operation to ripple
 * @param wss The array of inputs
 * @param direction The direction to ripple
 * @return The array of outputs and the final accumulator
 */
public func Ripple<V, G>(
    f : (Wire<V, G>, Wire<V, G>) -> Wire<V, G>,
    ws : Array<Wire<V, G>>,
    direction!: Direction = TOP_TO_BOTTOM
) : Wire<V, G>
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    Ripple<V, G>(
        { acc : Array<Wire<V, G>>, cur : Array<Wire<V, G>> =>
            let newAcc = f(acc[0], cur[0])
            [newAcc]
        },
        map({ w : Wire<V, G> => [w] }, ws),
        direction: direction
    )[0]
}
public func BitwiseRipple<V, G>(
    f : (Array<Wire<V, G>>, Array<Wire<V, G>>) -> Array<Wire<V, G>>,
    initial : Array<Wire<V, G>>,
    ws : Array<Wire<V, G>>,
    direction!: Direction = TOP_TO_BOTTOM
) : Array<Wire<V, G>>
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    let inputWires = BitwiseSplit(ws)
    Ripple(f, initial, inputWires, direction: direction)
}
public func BitwiseRipple<V, G>(
    f : (Wire<V, G>, Array<Wire<V, G>>) -> Wire<V, G>,
    initial : Wire<V, G>,
    ws : Array<Wire<V, G>>,
    direction!: Direction = TOP_TO_BOTTOM
) : Array<Wire<V, G>>
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    BitwiseRipple(
        { acc : Array<Wire<V, G>>, cur : Array<Wire<V, G>> =>
            let newAcc = f(acc[0], cur)
            [newAcc]
        },
        [initial],
        ws,
        direction: direction
    )
}
public func BitwiseRipple<V, G>(
    f : (Array<Wire<V, G>>, Array<Wire<V, G>>) -> Array<Wire<V, G>>,
    ws : Array<Wire<V, G>>,
    direction!: Direction = TOP_TO_BOTTOM
) : Array<Wire<V, G>>
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    let inputWires = BitwiseSplit(ws)
    let (first, rest) = GetFirstAndRest(inputWires)
    Ripple(f, first, rest, direction: direction)
}
public func BitwiseRipple<V, G>(
    f : (Wire<V, G>, Wire<V, G>) -> Wire<V, G>,
    ws : Array<Wire<V, G>>,
    direction!: Direction = TOP_TO_BOTTOM
) : Array<Wire<V, G>>
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    BitwiseRipple(
        { acc : Array<Wire<V, G>>, cur : Array<Wire<V, G>> =>
            let newAcc = f(acc[0], cur[0])
            [newAcc]
        },
        ws,
        direction: direction
    )
}
public func BitwiseRippleMap<V, G>(
    f : (Array<Wire<V, G>>, Array<Wire<V, G>>) -> (Array<Wire<V, G>>, Array<Wire<V, G>>),
    initial : Array<Wire<V, G>>,
    ws : Array<Wire<V, G>>,
    direction!: Direction = TOP_TO_BOTTOM
) : (Array<Wire<V, G>>, Array<Wire<V, G>>)
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    let inputWires = BitwiseSplit(ws)
    let (output, acc) = RippleMap(f, initial, inputWires, direction: direction)
    let combinedOutput = BitwiseCombine(output)
    (combinedOutput, acc)
}
public func BitwiseRippleMap<V, G>(
    f : (Wire<V, G>, Array<Wire<V, G>>) -> (Wire<V, G>, Wire<V, G>),
    initial : Wire<V, G>,
    ws : Array<Wire<V, G>>,
    direction!: Direction = TOP_TO_BOTTOM
) : (Wire<V, G>, Wire<V, G>)
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    let inputWires = BitwiseSplit(ws)
    let (output, acc) = RippleMap(
        { acc : Array<Wire<V, G>>, cur : Array<Wire<V, G>> =>
            let (newCur, newAcc) = f(acc[0], cur)
            ([newCur], [newAcc])
        }, [initial], inputWires, direction: direction)
    let combinedOutput = BitwiseCombine(output)
    (combinedOutput[0], acc[0])
}
public func BitwiseRippleMap<V, G>(
    f : (Wire<V, G>, Wire<V, G>) -> (Wire<V, G>, Wire<V, G>),
    initial : Wire<V, G>,
    ws : Wire<V, G>,
    direction!: Direction = TOP_TO_BOTTOM
) : (Wire<V, G>, Wire<V, G>)
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    let (output, acc) = BitwiseRippleMap(
        { acc : Array<Wire<V, G>>, cur : Array<Wire<V, G>> =>
            let (newOut, newAcc) = f(acc[0], cur[0])
            ([newOut], [newAcc])
        },
        [initial],
        [ws],
        direction: direction
    )
    (output[0], acc[0])
}
public func BitwiseRippleMap<V, G>(
    f : (Array<Wire<V, G>>, Array<Wire<V, G>>) -> (Array<Wire<V, G>>, Array<Wire<V, G>>),
    ws : Array<Wire<V, G>>,
    direction!: Direction = TOP_TO_BOTTOM
) : (Array<Wire<V, G>>, Array<Wire<V, G>>)
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    let inputWires = BitwiseSplit(ws)
    let (first, rest) = GetFirstAndRest(inputWires)
    let (output, acc) = RippleMap(f, first, rest, direction: direction)
    (BitwiseCombine(output), acc)

}
public func BitwiseRippleMap<V, G>(
    f : (Wire<V, G>, Wire<V, G>) -> (Wire<V, G>, Wire<V, G>),
    w : Wire<V, G>,
    direction!: Direction = TOP_TO_BOTTOM
) : (Wire<V, G>, Wire<V, G>)
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    let inputWires = BitwiseSplit([w])
    let (first, rest) = GetFirstAndRest(inputWires)
    let (output, acc) = RippleMap(
        { acc : Array<Wire<V, G>>, cur : Array<Wire<V, G>> =>
            let (newOut, newAcc) = f(acc[0], cur[0])
            ([newOut], [newAcc])
        }, first, rest, direction: direction)
    (BitwiseCombine(output)[0], acc[0])
}