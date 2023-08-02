package components.constructions

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
    inputWires : Array<Wire<V, G>>,
    accBundleWidth: Int64,
    inputBundleWidth: Int64,
    direction!: Direction = TOP_TO_BOTTOM,
    start!: Int64 = 0,
    end!: Int64 = (inputWires.size - accBundleWidth) / inputBundleWidth
) : Array<Wire<V, G>>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    let function =
        { acc : Array<Wire<V, G>>, cur : Array<Wire<V, G>> =>
            let curAcc = f(acc, cur)
            (Array<Wire<V, G>>(), curAcc)
        }
    RippleMap(
        function, inputWires, accBundleWidth, inputBundleWidth,
        0, direction: direction, start: start, end: end
    )
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
    inputWires : Array<Wire<V, G>>,
    accBundleWidth: Int64,
    inputBundleWidth: Int64,
    direction!: Direction = TOP_TO_BOTTOM,
    start!: Int64 = 0,
    end!: Int64 = (inputWires.size - accBundleWidth) / inputBundleWidth
) : Wire<V, G>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    let rippleFunction =
        { acc : Array<Wire<V, G>>, cur : Array<Wire<V, G>> =>
            let curAcc = f(acc[0], cur)
            [curAcc]
        }
    Ripple(
        rippleFunction, inputWires, accBundleWidth, inputBundleWidth,
        direction: direction, start: start, end: end
    )[0]
}
/**
* Connect some inputs to a rippled primitive
*
* @param prim The primitive to ripple
* @param ws The input wires
* @return The output wire from the rippled gate
*/
public func UseRippleGate<V, G>(
    prim : G, ws : Array<Wire<V, G>>, delay!: Int64 = 0
) : Array<Wire<V, G>>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    AssertNonEmpty(ws)
    AssertMinimumLength(ws, prim.GetArity())
    let width = AssertAllSameWidth(ws)
    UseSubcircuit(MakeRippleGate(prim, ws.size, width, delay: delay), ws)
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
    prim : G, n : Int64, w : Int64, delay!: Int64 = 0
) : InterfacedHypergraph<V, G>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    // let inputWires = Array<Array<Wire<V, G>>>(n, {
    //     i : Int64 => [UseWire<V, G>(w)]
    // })
    // let output = Ripple<V, G>(
    //     { acc : Array<Wire<V, G>>, cur : Array<Wire<V, G>> =>
    //         UseGate(prim, [acc[0], cur[0]], delay: delay)
    //     },
    //     inputWires, 1, 1
    // )[0]
    // MakeSubcircuit(
    //     mapi(
    //         {inputs : Array<Wire<V, G>>, i : Int64 =>
    //             InterfaceWire(inputs[0], numToUppercaseLetter(i))
    //         },
    //         inputs
    //     ),
    //     [InterfaceWire(output, "Z")],
    //     COMPOSITE(
    //         Specification(
    //             "${prim.GetName()}_${n}_${w}",
    //             Array<Port>(n, { i => Port(w, numToUppercaseLetter(i)) }),
    //             [Port(w)]
    //         )
    //     )
    // )
    throw Exception("to do")
}