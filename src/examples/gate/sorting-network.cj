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
/**
 * A sorting comparator black box component
 *
 * @param width The width of the wires
 * @param w1 The first wire to sort
 * @param w2 The second wire to sort
 * @return (small, large)
 */
func SortingComparator(width : Int64, w1 : Wire_, w2 : Wire_) : (Wire_, Wire_) {
    let bb = belnapSignature.AddBlackbox(
        "cmp${width}",
        [Port(width), Port(width)],
        [Port(width), Port(width)]
    )
    let cmp = UseBlackbox(bb, [w1, w2])
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
        throw IllegalArgumentException("Sorting network cannot have 0 inputs")
    }
    let inputWires = sig.UseWires(width, inputs)
    let outputWires =
        // A sorting network on one wire is just the identity
        if(inputs == 1){
            inputWires
        } else if(inputs == 2) {
            let (small, big) = SortingComparator(
                width, inputWires[0], inputWires[1]
            )
            [small, big]
        } else {
            // Otherwise we recursively sort the first inputs-1 wires
            let smallerWires = Array<Wire_>(inputWires.size - 1){
                i : Int64 => inputWires[i]
            }
            let smallerNetwork = UseSubcircuit(
                SortingNetwork(width, inputs - 1),
                smallerWires
            )
            // Ripple the sorting comparators across the wires
            RippleMap(
                { acc, cur => SortingComparator(width, cur, acc)},
                inputWires[inputs - 1],
                smallerNetwork,
                direction: BOTTOM_TO_TOP
            )
        }
    AssertHasLength(outputWires, inputs)
    MakeSubcircuit(
        NameWires(inputWires, { i : Int64 => "I${i}"}),
        NameWires(outputWires, { i : Int64 => "O${i}"}),
        "sort${inputs}_${width}"
    )
}