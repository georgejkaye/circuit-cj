/**
 * components/construction
 *
 * Functions for constructing 'higher-order circuits' using the functional
 * paradigms of map and fold.
 *
 * @author George Kaye
 * @since 0.2
 */
package components
from std import collection.ArrayList
/**
 * Directions that a ripple can be applied.
 */
public enum Direction {
    | TOP_TO_BOTTOM
    | BOTTOM_TO_TOP
}
/**
 * Given a function that transforms arrays of wires into a single wire,
 * generalise it so that it produces an array of wires instead, by wrapping the
 * outputs into an array
 *
 * @param f The function to generalise
 * @return The generalised function
 */
func GeneraliseSingleOutputFunction<V, G>(
    f : (Array<Wire<V, G>>) -> Wire<V, G>
) : (Array<Wire<V, G>>) -> Array<Wire<V, G>>
    where
        V <: ValueSymbol<V> & Equatable<V> & LessOrEqual<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
{
    { inputs : Array<Wire<V, G>> => [f(inputs)] }
}
/**
 * Given an array of arrays of wires, which are assumed to each contain one
 * element, flatten it into an array of wires, where each element is the zeroth
 * element of the original array elements.
 *
 * @param inputss The array of arrays of wires
 * @return The flattened array
 */
func FlattenSingleWireOutputs<V, G>(
    inputss : Array<Array<Wire<V, G>>>
) : Array<Wire<V, G>>
    where
        V <: ValueSymbol<V> & Equatable<V> & LessOrEqual<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
{
    map({ inputs : Array<Wire<V, G>> => inputs[0] }, inputss)
}
/**
 * Given an array of arrays of wires, apply an operation that transforms an
 * array of wires into a new array of wires, to each array of wires in the
 * input.
 *
 * @param f The operation to apply
 * @param inputss The array of arrays of wires
* @return The output array of arrays of wires
 */
public func Map<V, G>(
    f : (Array<Wire<V, G>>) -> Array<Wire<V, G>>,
    inputss : Array<Array<Wire<V, G>>>
) : Array<Array<Wire<V, G>>>
    where
        V <: ValueSymbol<V> & Equatable<V> & LessOrEqual<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
{
    let width = AssertArrayArraysSameWidths(inputss)
    map({inputs : Array<Wire<V, G>> => f(inputs)}, inputss)
}
/**
 * Given an array of arrays of wires, apply an operation that transforms an
 * array of wires into a new wire, to each array of wires in the input.
 *
 * @param f The operation to apply
 * @param inputss The array of arrays of wires
 * @return The output array of wires
 */
public func Map<V, G>(
    f : (Array<Wire<V, G>>) -> Wire<V, G>,
    inputss : Array<Array<Wire<V, G>>>
) : Array<Wire<V, G>>
    where
        V <: ValueSymbol<V> & Equatable<V> & LessOrEqual<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
{
    let outputWires = Map(GeneraliseSingleOutputFunction(f), inputss)
    FlattenSingleWireOutputs(outputWires)
}
/**
 * Given an array of wires, split them to create an array of arrays of one-bit
 * wires of the form output[i][j] = input[j][i].
 *
 * @param inputs The array of wires to split
 * @return The array of arrays of split wires
 */
public func BitwiseSplit<V, G>(
    inputs : Array<Wire<V, G>>
) : Array<Array<Wire<V, G>>>
    where
        V <: ValueSymbol<V> & Equatable<V> & LessOrEqual<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
{
    let width = AssertAllSameWidth(inputs)
    let splitInputs = map({ w : Wire<V, G> => Split(w) }, inputs)
    Array<Array<Wire<V, G>>>(width){ i : Int64 =>
        Array<Wire<V, G>>(inputs.size){ j : Int64 => splitInputs[j][i] }
    }
}
/**
 * Given an array of arrays of wires, combine them to create an array of wires,
 * so that inputs[i] = [inputss[0][i], inputss[1][i], ...].
 *
 * @param inputss The array of arrays of wires to combine
 * @return The array of combined wires
 */
public func BitwiseCombine<V, G>(
    inputss : Array<Array<Wire<V, G>>>
) : Array<Wire<V, G>>
    where
        V <: ValueSymbol<V> & Equatable<V> & LessOrEqual<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
{
    let size = AssertArrayArraysSameWidths(inputss)
    Array<Wire<V, G>>(size){
        i : Int64 => Combine(Array<Wire<V, G>>(inputss.size){
            j : Int64 => inputss[j][i]
        })
    }
}
/**
 * Perform a bitwise map.
 *
 * @param f (input array) -> output array
 * @param input array
 * @return output wire
 */
public func BitwiseMap<V, G>(
    f : (Array<Wire<V, G>>) -> Array<Wire<V, G>>,
    inputs : Array<Wire<V, G>>
) : Array<Wire<V, G>>
    where
        V <: ValueSymbol<V> & Equatable<V> & LessOrEqual<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
{
    let inputWires = BitwiseSplit(inputs)
    let outputWires = Map(f, inputWires)
    BitwiseCombine(outputWires)
}
/**
 * Perform a bitwise map.
 *
 * @param f (input array) -> output wire
 * @param input wire
 * @return output wire
 */
public func BitwiseMap<V, G>(
    f : (Array<Wire<V, G>>) -> Wire<V, G>,
    inputs : Array<Wire<V, G>>
) : Wire<V, G>
    where
        V <: ValueSymbol<V> & Equatable<V> & LessOrEqual<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
{
    BitwiseMap({ inputs : Array<Wire<V, G>> => [f(inputs)] }, inputs)[0]
}
/**
 * Perform a bitwise map.
 *
 * @param f (input wire) -> output wire
 * @param input wire
 * @return output wire
 */
public func BitwiseMap<V, G>(
    f : (Wire<V, G>) -> Wire<V, G>,
    input : Wire<V, G>
) : Wire<V, G>
    where
        V <: ValueSymbol<V> & Equatable<V> & LessOrEqual<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
{
    BitwiseMap({ inputs : Array<Wire<V, G>> => [f(inputs[0])] }, [input])[0]
}
/**
 * Perform a ripple map.
 *
 * @param f (acc array, cur array) -> (out array, acc array)
 * @param inputs array array
 * @param direction
 * @param start
 * @param end
 * @return outputs array array, acc array
 */
public func RippleMap<V, G>(
    f : (Array<Wire<V, G>>, Array<Wire<V, G>>) ->
            (Array<Wire<V, G>>, Array<Wire<V, G>>),
    initial : Array<Wire<V, G>>,
    inputs : Array<Array<Wire<V, G>>>,
    direction!: Direction = TOP_TO_BOTTOM,
    start!: Int64 = 0,
    end!: Int64 = inputs.size
) : (Array<Array<Wire<V, G>>>, Array<Wire<V, G>>)
    where
        V <: ValueSymbol<V> & Equatable<V> & LessOrEqual<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
{
    let width = AssertArrayArraysSameWidths(inputs)
    var acc = initial
    let outputs = ArrayList<Array<Wire<V, G>>>()
    for(i in start..end) {
        let j = match(direction) {
            case TOP_TO_BOTTOM => i
            case BOTTOM_TO_TOP => inputs.size - 1 - i
        }
        let cur = inputs[j]
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
 * Perform a ripple map.
 *
 * @param f (acc wire, cur array) -> (out array, acc wire)
 * @param inputs array array
 * @param direction
 * @param start
 * @param end
 * @return outputs array array, acc wire
 */
public func RippleMap<V, G>(
    f : (Wire<V, G>, Array<Wire<V, G>>) -> (Array<Wire<V, G>>, Wire<V, G>),
    initial : Wire<V, G>,
    inputs : Array<Array<Wire<V, G>>>,
    direction!: Direction = TOP_TO_BOTTOM,
    start!: Int64 = 0,
    end!: Int64 = inputs.size
) : (Array<Array<Wire<V, G>>>, Wire<V, G>)
    where
        V <: ValueSymbol<V> & Equatable<V> & LessOrEqual<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
{
    let rippleMapFunction =
        { acc : Array<Wire<V, G>>, cur : Array<Wire<V, G>> =>
            let (curOutput, curAcc) = f(acc[0], cur)
            (curOutput, [curAcc])
        }
    let (outputs, acc) = RippleMap(
        rippleMapFunction, [initial], inputs, direction: direction,
        start: start, end: end
    )
    (outputs, acc[0])
}
/**
 * Perform a ripple map.
 *
 * @param f (acc wire, cur wire) -> (out wire, acc wire)
 * @param inputs array array
 * @param direction
 * @param start
 * @param end
 * @return outputs array, acc wire
 */
public func RippleMap<V, G>(
    f : (Wire<V, G>, Wire<V, G>) -> (Wire<V, G>, Wire<V, G>),
    initial : Wire<V, G>,
    inputs : Array<Wire<V, G>>,
    direction!: Direction = TOP_TO_BOTTOM,
    start!: Int64 = 0,
    end!: Int64 = inputs.size
) : (Array<Wire<V, G>>, Wire<V, G>)
    where
        V <: ValueSymbol<V> & Equatable<V> & LessOrEqual<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
{
    let (finalOut, finalAcc) = RippleMap(
        { acc : Array<Wire<V, G>>, cur : Array<Wire<V, G>> =>
            let (newOut, newCur) = f(acc[0], cur[0])
            ([newOut], [newCur])
        },
        [initial],
        map({ w : Wire<V, G> => [w] }, initial),
        direction: direction,
        start: start,
        end: end
    )
    (FlattenSingleWireOutputs(finalOut), finalAcc[0])
}
/**
 * Perform a ripple map, with the first input wire as the start wire for the
 * accumulator.
 *
 * @param f (acc wire, cur wire) -> (out wire, acc wire)
 * @param inputs array array
 * @param direction
 * @param start
 * @param end
 * @return outputs array array, acc array
 */
public func RippleMap<V, G>(
    f : (Array<Wire<V, G>>, Array<Wire<V, G>>) ->
            (Array<Wire<V, G>>, Array<Wire<V, G>>),
    inputs : Array<Array<Wire<V, G>>>,
    direction!: Direction = TOP_TO_BOTTOM,
    start!: Int64 = 0,
    end!: Int64 = inputs.size
) : (Array<Array<Wire<V, G>>>, Array<Wire<V, G>>)
    where
        V <: ValueSymbol<V> & Equatable<V> & LessOrEqual<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
{
    RippleMap(
        f, inputs[start], inputs, direction: direction,
        start: start + 1, end: end
    )
}
/**
 * Perform a ripple map, with the first input wire as the start wire for the
 * accumulator.
 *
 * @param f (acc wire, cur wire) -> (out wire, acc wire)
 * @param inputs array
 * @param direction
 * @param start
 * @param end
 * @return outputs array, acc wire
 */
public func RippleMap<V, G>(
    f : (Wire<V, G>, Wire<V, G>) -> (Wire<V, G>, Wire<V, G>),
    inputs : Array<Wire<V, G>>,
    direction!: Direction = TOP_TO_BOTTOM,
    start!: Int64 = 0,
    end!: Int64 = inputs.size
) : (Array<Wire<V, G>>, Wire<V, G>)
    where
        V <: ValueSymbol<V> & Equatable<V> & LessOrEqual<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
{
    let function =
        { acc : Array<Wire<V, G>>, cur : Array<Wire<V, G>> =>
            let (curRes, curAcc) = f(acc[0], cur[0])
            ([curRes], [curAcc])
        }
    let (outputs, acc) = RippleMap<V, G>(
        function, map({ w : Wire<V, G> => [w] }, inputs), direction: direction,
        start: start, end: end
    )
    (FlattenSingleWireOutputs(outputs), acc[0])
}
/**
 * Perform a ripple.
 *
 * @param f (acc array, cur array) -> acc array
 * @param initial array
 * @param inputs array array
 * @param direction
 * @param start
 * @param end
 * @return acc wire
 */
public func Ripple<V, G>(
    f : (Array<Wire<V, G>>, Array<Wire<V, G>>) -> Array<Wire<V, G>>,
    initial : Array<Wire<V, G>>,
    inputs : Array<Array<Wire<V, G>>>,
    direction!: Direction = TOP_TO_BOTTOM,
    start!: Int64 = 0,
    end!: Int64 = inputs.size
) : Array<Wire<V, G>>
    where
        V <: ValueSymbol<V> & Equatable<V> & LessOrEqual<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
{
    let function =
        { acc : Array<Wire<V, G>>, cur : Array<Wire<V, G>> =>
            let curAcc = f(acc, cur)
            (Array<Wire<V, G>>(), curAcc)
        }
    let (_, acc) = RippleMap(
        function, initial, inputs, direction: direction,
        start: start, end: end
    )
    acc
}
/**
 * Perform a ripple.
 *
 * @param f (acc wire, cur array) -> acc wire
 * @param initial wire
 * @param inputs array
 * @param direction
 * @param start
 * @param end
 * @return acc wire
 */
public func Ripple<V, G>(
    f : (Wire<V, G>, Array<Wire<V, G>>) -> Wire<V, G>,
    initial : Wire<V, G>,
    inputs : Array<Array<Wire<V, G>>>,
    direction!: Direction = TOP_TO_BOTTOM,
    start!: Int64 = 0,
    end!: Int64 = inputs.size
) : Wire<V, G>
    where
        V <: ValueSymbol<V> & Equatable<V> & LessOrEqual<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
{
    let rippleFunction =
        { acc : Array<Wire<V, G>>, cur : Array<Wire<V, G>> =>
            let curAcc = f(acc[0], cur)
            [curAcc]
        }
    Ripple(
        rippleFunction, [initial], inputs, direction: direction,
        start: start, end: end
    )[0]
}
/**
 * Perform a ripple.
 *
 * @param f (acc array, cur array) -> acc array
 * @param initial wire
 * @param inputs array
 * @param direction
 * @param start
 * @param end
 * @return acc array
 */
public func Ripple<V, G>(
    f : (Array<Wire<V, G>>, Array<Wire<V, G>>) -> Array<Wire<V, G>>,
    inputs : Array<Array<Wire<V, G>>>,
    direction!: Direction = TOP_TO_BOTTOM,
    start!: Int64 = 0,
    end!: Int64 = inputs.size
) : Array<Wire<V, G>>
    where
        V <: ValueSymbol<V> & Equatable<V> & LessOrEqual<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
{
    Ripple(
        f, inputs[start], inputs, direction: direction,
        start: start + 1, end: end
    )
}
/**
 * Perform a ripple.
 *
 * @param f (acc wire, cur wire) -> acc wire
 * @param initial wire
 * @param inputs array
 * @param direction
 * @param start
 * @param end
 * @return acc wire
 */
public func Ripple<V, G>(
    f : (Wire<V, G>, Wire<V, G>) -> Wire<V, G>,
    inputs : Array<Wire<V, G>>,
    direction!: Direction = TOP_TO_BOTTOM,
    start!: Int64 = 0,
    end!: Int64 = inputs.size
) : Wire<V, G>
    where
        V <: ValueSymbol<V> & Equatable<V> & LessOrEqual<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
{
    let rippleFunction =
        { acc : Array<Wire<V, G>>, cur : Array<Wire<V, G>> =>
            let newAcc = f(acc[0], cur[0])
            [newAcc]
        }
    Ripple<V, G>(
        rippleFunction, map({ w : Wire<V, G> => [w] }, inputs),
        direction: direction, start: start, end: end
    )[0]
}
/**
 * Perform a bitwise ripple.
 *
 * @param f (acc array, cur array) -> acc array
 * @param initial wire
 * @param inputs array
 * @param direction
 * @param start
 * @param end
 * @return acc array
 */
public func BitwiseRipple<V, G>(
    f : (Array<Wire<V, G>>, Array<Wire<V, G>>) -> Array<Wire<V, G>>,
    initial : Array<Wire<V, G>>,
    inputs : Array<Wire<V, G>>,
    direction!: Direction = TOP_TO_BOTTOM,
    start!: Int64 = 0,
    end!: Int64 = inputs.size
) : Array<Wire<V, G>>
    where
        V <: ValueSymbol<V> & Equatable<V> & LessOrEqual<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
{
    let inputWires = BitwiseSplit(inputs)
    Ripple(f, initial, inputWires, direction: direction, start: start, end: end)
}
/**
 * Perform a bitwise ripple.
 *
 * @param f (acc wire, cur array) -> acc wire
 * @param initial wire
 * @param inputs array
 * @param direction
 * @param start
 * @param end
 * @return acc array
 */
public func BitwiseRipple<V, G>(
    f : (Wire<V, G>, Array<Wire<V, G>>) -> Wire<V, G>,
    initial : Wire<V, G>,
    inputs : Array<Wire<V, G>>,
    direction!: Direction = TOP_TO_BOTTOM,
    start!: Int64 = 0,
    end!: Int64 = inputs.size
) : Wire<V, G>
    where
        V <: ValueSymbol<V> & Equatable<V> & LessOrEqual<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
{
    let function =
        { acc : Array<Wire<V, G>>, cur : Array<Wire<V, G>> =>
            let newAcc = f(acc[0], cur)
            [newAcc]
        }
    BitwiseRipple(function, [initial], inputs, direction: direction)[0]
}
/**
 * Perform a bitwise ripple.
 *
 * @param f (acc array, cur array) -> acc array
 * @param initial wire
 * @param inputs array
 * @param direction
 * @param start
 * @param end
 * @return acc array
 */
public func BitwiseRipple<V, G>(
    f : (Array<Wire<V, G>>, Array<Wire<V, G>>) -> Array<Wire<V, G>>,
    inputs : Array<Wire<V, G>>,
    direction!: Direction = TOP_TO_BOTTOM,
    start!: Int64 = 0,
    end!: Int64 = inputs.size
) : Array<Wire<V, G>>
    where
        V <: ValueSymbol<V> & Equatable<V> & LessOrEqual<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
{
    let inputWires = BitwiseSplit(inputs)
    Ripple(
        f, inputWires[start], inputWires, direction: direction,
        start: start + 1, end: end
    )
}
/**
 * Perform a bitwise ripple.
 *
 * @param f (acc wire, cur wire) -> acc wire
 * @param initial wire
 * @param inputs array
 * @param direction
 * @param start
 * @param end
 * @return acc array
 */
public func BitwiseRipple<V, G>(
    f : (Wire<V, G>, Wire<V, G>) -> Wire<V, G>,
    inputs : Array<Wire<V, G>>,
    direction!: Direction = TOP_TO_BOTTOM,
    start!: Int64 = 0,
    end!: Int64 = inputs.size
) : Wire<V, G>
    where
        V <: ValueSymbol<V> & Equatable<V> & LessOrEqual<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
{
    let function =
        { acc : Array<Wire<V, G>>, cur : Array<Wire<V, G>> =>
            let newAcc = f(acc[0], cur[0])
            [newAcc]
        }
    BitwiseRipple(
        function, inputs, direction: direction, start: start, end: end
    )[0]
}
/**
 * Perform a bitwise ripple map.
 *
 * @param f (acc array, cur array) -> (out array, acc array)
 * @param initial array
 * @param inputs array
 * @param direction
 * @param start
 * @param end
 * @return (combined outputs array, acc array)
 */
public func BitwiseRippleMap<V, G>(
    f : (Array<Wire<V, G>>, Array<Wire<V, G>>) ->
            (Array<Wire<V, G>>, Array<Wire<V, G>>),
    initial : Array<Wire<V, G>>,
    inputs : Array<Wire<V, G>>,
    direction!: Direction = TOP_TO_BOTTOM,
    start!: Int64 = 0,
    end!: Int64 = inputs.size
) : (Array<Wire<V, G>>, Array<Wire<V, G>>)
    where
        V <: ValueSymbol<V> & Equatable<V> & LessOrEqual<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
{
    let inputWires = BitwiseSplit(inputs)
    let (output, acc) = RippleMap(
        f, initial, inputWires, direction: direction, start: start, end: end
    )
    let combinedOutput = BitwiseCombine(output)
    (combinedOutput, acc)
}
/**
 * Perform a bitwise ripple map.
 *
 * @param f (acc wire, cur array) -> (out wire, acc wire)
 * @param initial wire
 * @param inputs array
 * @param direction
 * @param start
 * @param end
 * @return (combined outputs wire, acc wire)
 */
public func BitwiseRippleMap<V, G>(
    f : (Wire<V, G>, Array<Wire<V, G>>) -> (Wire<V, G>, Wire<V, G>),
    initial : Wire<V, G>,
    inputs : Array<Wire<V, G>>,
    direction!: Direction = TOP_TO_BOTTOM,
    start!: Int64 = 0,
    end!: Int64 = inputs.size
) : (Wire<V, G>, Wire<V, G>)
    where
        V <: ValueSymbol<V> & Equatable<V> & LessOrEqual<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
{
    let inputWires = BitwiseSplit(inputs)
    let function =
        { acc : Array<Wire<V, G>>, cur : Array<Wire<V, G>> =>
            let (newCur, newAcc) = f(acc[0], cur)
            ([newCur], [newAcc])
        }
    let (output, acc) = RippleMap(
        function, [initial], inputWires, direction: direction,
        start: start, end: end)
    let combinedOutput = BitwiseCombine(output)
    (combinedOutput[0], acc[0])
}
/**
 * Perform a bitwise ripple map.
 *
 * @param f (acc, cur) -> (out, acc)
 * @param initial
 * @param inputs
 * @param direction
 * @return The combined outputs and the final accumulator
 */
public func BitwiseRippleMap<V, G>(
    f : (Wire<V, G>, Wire<V, G>) -> (Wire<V, G>, Wire<V, G>),
    initial : Wire<V, G>,
    input : Wire<V, G>,
    direction!: Direction = TOP_TO_BOTTOM
) : (Wire<V, G>, Wire<V, G>)
    where
        V <: ValueSymbol<V> & Equatable<V> & LessOrEqual<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
{
    let function =
        { acc : Array<Wire<V, G>>, cur : Array<Wire<V, G>> =>
            let (newOut, newAcc) = f(acc[0], cur[0])
            ([newOut], [newAcc])
        }
    let (output, acc) = BitwiseRippleMap(
        function, [initial], [input], direction: direction
    )
    (output[0], acc[0])
}
/**
 * Perform a bitwise ripple map with the first input as the initial value of
 * the accumulator.
 *
 * @param f (acc array, cur array) -> (out array, acc array)
 * @param inputs
 * @param direction
 * @return (output array, acc array)
 */
public func BitwiseRippleMap<V, G>(
    f : (Array<Wire<V, G>>, Array<Wire<V, G>>) ->
            (Array<Wire<V, G>>, Array<Wire<V, G>>),
    inputs : Array<Wire<V, G>>,
    direction!: Direction = TOP_TO_BOTTOM
) : (Array<Wire<V, G>>, Array<Wire<V, G>>)
    where
        V <: ValueSymbol<V> & Equatable<V> & LessOrEqual<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
{
    let inputWires = BitwiseSplit(inputs)
    let (output, acc) = RippleMap(
        f, inputWires[0], inputWires, direction: direction, start: 1
    )
    (BitwiseCombine(output), acc)
}
/**
 * Perform a bitwise ripple map with the first input as the initial value of
 * the accumulator.
 *
 * @param f (acc wire, cur wire) -> (out wire, acc wire)
 * @param input
 * @param direction
 * @return (output wire, acc wire)
 */
public func BitwiseRippleMap<V, G>(
    f : (Wire<V, G>, Wire<V, G>) -> (Wire<V, G>, Wire<V, G>),
    input : Wire<V, G>,
    direction!: Direction = TOP_TO_BOTTOM
) : (Wire<V, G>, Wire<V, G>)
    where
        V <: ValueSymbol<V> & Equatable<V> & LessOrEqual<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
{
    let inputWires = BitwiseSplit([input])
    let function =
        { acc : Array<Wire<V, G>>, cur : Array<Wire<V, G>> =>
            let (newOut, newAcc) = f(acc[0], cur[0])
            ([newOut], [newAcc])
        }
    let (output, acc) = RippleMap(
        function, inputWires[0], inputWires, direction: direction, start: 1
    )
    (BitwiseCombine(output)[0], acc[0])
}

/**
 * Make a circuit that applies a given primitive bitwise, i.e. the primitive
 * will be applied to each bit of the input wires independently
 *
 * @param prim The primitive to apply
 * @param w The width of the input wires
 * @return The bitwise gate circuit
 */
public func MakeBitwiseMapGate<V, G>(
    prim : G,
    w : Int64
) : InterfacedHypergraph<V, G>
    where
        V <: ValueSymbol<V> & Equatable<V> & LessOrEqual<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
{
    let inputs = Array<Wire<V, G>>(
        prim.GetArity(),
        {i : Int64 => UseWire<V, G>(w) }
    )
    let output = BitwiseMap(
        { inputs : Array<Wire<V, G>> => UseGate(prim, inputs) },
        inputs
    )[0]
    MakeSubcircuit(
        mapi(
            { w : Wire<V, G>, i : Int64 =>
                InterfaceWire(w, numToUppercaseLetter(i))
            },
            inputs
        ),
        [InterfaceWire(output, "Z")],
        ENHANCED_PRIMITIVE(
            EnhancedPrimitive(
                prim,
                BITWISE_MAP(w)
            )
        )
    )
}
/**
 * Make a circuit that ripples a given primitive over some inputs, i.e. the
 * primitive will be applied to each input wire one at a time in succession
 *
 * @param prim The primitive to apply
 * @param n The number of input wires
 * @param w The width of the input wires
 * @return The ripple gate circuit
 */
public func MakeRippleGate<V, G>(
    prim : G,
    n : Int64,
    w : Int64
) : InterfacedHypergraph<V, G>
    where
        V <: ValueSymbol<V> & Equatable<V> & LessOrEqual<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
{
    let inputs = Array<Array<Wire<V, G>>>(n, {
        i : Int64 => [UseWire<V, G>(w)]
    })
    let output = Ripple(
        { acc : Array<Wire<V, G>>, cur : Array<Wire<V, G>> =>
            UseGate(prim, [acc[0], cur[0]])
        },
        inputs
    )[0]
    MakeSubcircuit(
        mapi(
            {inputs : Array<Wire<V, G>>, i : Int64 =>
                InterfaceWire(inputs[0], numToUppercaseLetter(i))
            },
            inputs
        ),
        [InterfaceWire(output, "Z")],
        ENHANCED_PRIMITIVE(
            EnhancedPrimitive(
                prim,
                RIPPLE(n-1)
            )
        )
    )
}
/**
 * Make a circuit that ripples a given primitive over the bits in a single
 * wire, i.e. the primitive will be applied to each bit wire one at a time in
 * succession.
 *
 * @param prim The primitive to apply
 * @param w The width of the input wire
 * @return The internal ripple gate circuit
 */
public func MakeBitwiseRippleGate<V, G>(
    prim : G,
    w : Int64
) : InterfacedHypergraph<V, G>
    where
        V <: ValueSymbol<V> & Equatable<V> & LessOrEqual<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
{
    let input = UseWire<V, G>(w)
    let output = BitwiseRipple(
        { acc : Array<Wire<V, G>>, cur : Array<Wire<V, G>> =>
            UseGate(prim, [acc[0], cur[0]])
        },
        [input]
    )[0]
    MakeSubcircuit(
        [InterfaceWire(input, "A")],
        [InterfaceWire(output, "Z")],
        ENHANCED_PRIMITIVE(
            EnhancedPrimitive(
                prim,
                BITWISE_RIPPLE(w-1)
            )
        )
    )
}