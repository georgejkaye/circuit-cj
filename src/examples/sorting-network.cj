/**
 * examples/sorting-network.cj
 *
 * An example of a sorting network
 * https://en.wikipedia.org/wiki/Sorting_network
 *
 * @author George Kaye
 * @since 0.1
 */

package examples

/**
 * A sorting comparator black box component
 *
 * @param width The width of the wires
 * @param w1 The first wire to sort
 * @param w2 The second wire to sort
 * @return The two output wires of the comparator
 */
func SortingComparator(width : Int64, w1 : Wire, w2 : Wire) {
    let cmp = BlackBox(
        "cmp${width}",
        [
            Port(width),
            Port(width)
        ],
        [
            Port(width),
            Port(width)
        ],
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
public func SortingNetwork(width : Int64, inputs : Int64) : InterfacedHypergraph {
    if(inputs == 0){
        throw NotImplemented("Sorting network cannot have 0 inputs")
    }
    let inputWires = sig.UseWires(inputs, width)
    let outputWires =
        // A sorting network on one wire is just the identity
        if(inputs == 1){
            inputWires
        } else {
            // Otherwise we recursively sort the first inputs-1 wires
            let smallerWires = inputWires.slice(0, inputs - 1).toArray()
            let smallerNetwork = UseSubcircuit(
                SortingNetwork(width, inputs - 1),
                smallerWires
            )
            // Concatenate the sorted inputs-1 wires with the original inputth wire
            let smallerSortedInputs = Array<Wire>(
                inputs,
                { i : Int64 =>
                    if(i == inputs - 1) {
                        inputWires[inputs - 1]
                    } else {
                        smallerNetwork[i]
                    }
                }
            )
            // Ripple the sorting comparators across the wires
            Ripple(
                smallerSortedInputs,
                {
                    prev : Wire, cur : Wire =>
                        let (toNext, toOutput) = SortingComparator(width, cur, prev)
                        (toOutput, toNext)
                },
                direction: BOTTOM_TO_TOP
            )
        }
    MakeSubcircuit(
        NameWires(inputWires, { i : Int64 => "I${i}"}),
        NameWires(outputWires, { i : Int64 => "O${i}"}),
        "sort${inputs}_${width}"
    )
}