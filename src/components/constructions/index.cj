/**
 * components/constructions/index.cj
 *
 * Imports and shared functions for constructions package.
 */
package components.constructions

from std import collection.ArrayList

import syntax.*
import utils.*
import graphs.*
import components.*

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
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
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
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    map({ inputs : Array<Wire<V, G>> => inputs[0] }, inputss)
}