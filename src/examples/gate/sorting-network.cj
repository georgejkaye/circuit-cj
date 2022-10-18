/**
 * examples/sorting-network.cj
 *
 * An example of a sorting network
 * https://en.wikipedia.org/wiki/Sorting_network
 *
 * @author George Kaye
 * @since 0.1
 */

package examples.gate

import prelude.*

/**
 * A sorting comparator black box component
 *
 * @param width The width of the wires
 * @param w1 The first wire to sort
 * @param w2 The second wire to sort
 * @return The two output wires of the comparator
 */
func SortingComparator(width : Int64, w1 : Wire_, w2 : Wire_) : (Wire_, Wire_) {
    let cmp = BlackBox(
        "cmp${width}",
        [Port(width), Port(width)],
        [Port(width), Port(width)],
        [w1, w2]
    )
    (cmp[0], cmp[1])
}
/**
 * Naive sorting network
 * https://en.wikipedia.org/wiki/Sorting_network
 *
 * @param width The width of the input wires
 * @param inputs The number of inputs to sort
 * @return The sorting network
 */
public func SortingNetwork(width : Int64, inputs : Int64) : Circuit_ {
    if(inputs == 0){
        throw NotImplemented("Sorting network cannot have 0 inputs")
    }
    let inputWires = sig.UseWires(width, inputs)
    let outputWires =
        // A sorting network on one wire is just the identity
        if(inputs == 1){
            inputWires
        } else {
            // Otherwise we recursively sort the first inputs-1 wires
            let smallerWires = Array<Wire_>(inputWires.size - 1){i : Int64 => inputWires[i]}
            let smallerNetwork = UseSubcircuit(
                SortingNetwork(width, inputs - 1),
                smallerWires
            )
            // Ripple the sorting comparators across the wires
            let (output, final) = RippleMap_1<Value, Gate>(
                { acc : Array<Wire_>, cur : Array<Wire_> =>
                    let (next, out) = SortingComparator(width, cur[0], acc[0])
                    (out, next)
                },
                [inputWires[inputs - 1]],
                smallerNetwork,
                direction : BOTTOM_TO_TOP
            )
            concat(final, output)
        }
    MakeSubcircuit(
        sig.NameWires(inputWires, { i : Int64 => "I${i}"}),
        sig.NameWires(outputWires, { i : Int64 => "O${i}"}),
        "sort${inputs}_${width}"
    )
}