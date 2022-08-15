/**
 * components/values.cj
 *
 * Functions for building 'values', the signals that flow through
 * the wires of circuits. A primitive value is a generator 0->1:
 * values of larger widths can be constructed by composing these
 * in parallel.
 *
 * @author George Kaye
 * @since 0.1
 */

package components

from std import math.abs

import prelude.*
import syntax.*

/**
 * Convert a decimal number to a list of truth values
 * The list is ordered with the lsb first
 * e.g. 10 => [0, 1, 0, 1, 0, ...]
 * If signed, the negative numbers are represented in twos complement
 * @param w      The width of the resulting list
 * @param x      The decimal number to convert
 */
func UnsignedDecToBin(x : Int64, w : Int64) : Array<Bool> {
    AssertNonNegative(x)
    let required = log2Ceil(x+1)
    AssertEnoughBits(w, required)
    // Set up the list
    let bin = Array<Bool>(w, {x : Int64 => false})
    var num = x
    // Divide by two w times, setting the remainder to the ith bit of the list
    // If we run out of w before we run out of list, the msbs will be ignored
    for(i in 0..w){
        let rem = num % 2 == 1
        bin.set(w-i-1, rem)
        num = num / 2
    }
    return bin
}
/**
 * 'Add one' to an array of booleans, i.e. flip the lowest bit and
 * propagate the changes throughout the list
 * @param x The array of booleans
 */
func AddOne(x : Array<Bool>) : Unit {
    for (i in 0..(x.size - 1)) {
        let j = x.size - 1 - i
        if (x[j]) {
            x[j] = false
        } else {
            x[j] = true
            return
        }
    }
}
/**
 * Invert an array of bools, i.e. flip each bit
 * @param x The array of booleans
 */
func Invert(x : Array<Bool>) : Unit {
    for (i in 0..(x.size)){
        x[i] = !x[i]
    }
}
/**
 * Convert a decimal number to a bitstring of a fixed length,
 * interpreted as an array of booleans
 * @param x The number to convert
 * @param w The width of the bitstring
 * @return The corresponding bitstring
 */
func SignedDecToBin(x : Int64, w : Int64) : Array<Bool> {
    let bin = UnsignedDecToBin(abs(x), w)
    Invert(bin)
    AddOne(bin)
    bin
}
/**
 * Create an edge for a given value
 * @param vs The array of values
 * @param signed Whether the number is signed
 * @return The output wire
 */
public func MakeValue(vs : Array<Value>, signed : Bool) : Wire {
    MakeEdgeWithNewOutputs(
        VALUE(
            ValueSpec(vs, signed)
        ),
        Array<Wire>(),
        [vs.size],
        None
    )[0]
}
/**
 * Create an edge for a given value
 * @param vs The array of booleans
 * @param signed Whether the number is signed
 * @return The output wire
 */
public func MakeValue(vs : Array<Bool>, signed : Bool) {
    MakeValue(map({ b : Bool => if(b){ True } else { False }}, vs), signed)
}
/**
 * Use an unsigned value for a given number
 * @param x The number to convert
 * @param width The width of the resulting bitstring
 * @return The wire of the value
 */
public func UnsignedValueFromInt(x : Int64, width!: Int64) : Wire {
    let bin = UnsignedDecToBin(x, width)
    MakeValue(bin, false)
}
/**
 * Use a signed value for a given number
 * @param x The number to convert
 * @param width The width of the resulting bitstring
 * @return The wire of the value
 */
public func SignedValueFromInt(x : Int64, width!: Int64) : Wire {
    let bin = SignedDecToBin(x, width)
    MakeValue(bin, true)
}
/**
 * Create a zero value for a given width, i.e. all falses
 * @param width The width of the bitstring
 * @return The wire of the value
 */
public func Zero(width: Int64) : Wire {
    let values = Array<Value>(width, { i : Int64 => False })
    MakeValue(values, false)
}
/**
 * Create a constant zero waveform for a given width, i.e. all falses
 * @param width The width of the bitstring
 * @return The wire of the value
 */
public func ConstantZero(width: Int64) : Wire {
    let value = Zero(width)
    InfiniteWaveform(value)
}
/**
 * Create a constant zero waveform for one bit, i.e. a false
 * @return The wire of the value
 */
public func ConstantZero() : Wire {
    ConstantZero(1)
}
/**
 * Perform an unsigned extension on a wire, i.e. add a false as its msb
 * @param w The input wire
 * @return The wire with an extra bit
 */
public func UnsignedExtend(w : Wire) : Wire {
    let value = InfiniteWaveform(False)
    Combine([value, w])
}