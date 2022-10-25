package signatures.gate

import syntax.*
import components.*
import prelude.*

from std import math.abs

/**
 * Unary gates
 */

public func BufGate(
    a : BelnapWire
) : BelnapWire {
    UseUnaryGate(BUF, a)
}
public func NotGate(
    a : BelnapWire
) : BelnapWire {
    UseUnaryGate(NOT, a)
}

/**
 * Binary gates
 */

public func AndGate(
    a : BelnapWire,
    b : BelnapWire
) : BelnapWire {
    UseBinaryGate(AND, a, b)
}
public func OrGate(
    a : BelnapWire,
    b : BelnapWire
) : BelnapWire {
    UseBinaryGate(OR, a, b)
}
public func NandGate(
    a : BelnapWire,
    b : BelnapWire
) : BelnapWire {
    UseBinaryGate(NAND, a, b)
}
public func NorGate(
    a : BelnapWire,
    b : BelnapWire
) : BelnapWire {
    UseBinaryGate(NOR, a, b)
}
public func XorGate(
    a : BelnapWire,
    b : BelnapWire
) : BelnapWire {
    UseBinaryGate(XOR, a, b)
}
public func XnorGate(
    a : BelnapWire,
    b : BelnapWire
) : BelnapWire {
    UseBinaryGate(XNOR, a, b)
}
func DecToBin(x : Int64, w : Int64, signed : Bool) : Signal<GateLevelValue> {
    if(signed) {
        SignedDecToBin(x, w)
    } else {
        UnsignedDecToBin(x, w)
    }
}
/**
 * Convert a decimal number to a list of truth values
 * The list is ordered with the lsb first
 * e.g. 10 => [0, 1, 0, 1, 0, ...]
 * If signed, the negative numbers are represented in twos complement
 * @param w      The width of the resulting list
 * @param x      The decimal number to convert
 */
func UnsignedDecToBin(x : Int64, w : Int64) : Signal<GateLevelValue> {
    AssertNonNegative(x)
    let required = log2Ceil(x+1)
    AssertEnoughBits(w, required)
    // Set up the list
    let bin = Array<GateLevelValue>(w, {x : Int64 => FALSE})
    var num = x
    // Divide by two w times, setting the remainder to the ith bit of the list
    // If we run out of w before we run out of list, the msbs will be ignored
    for(i in 0..w){
        let rem = if(num % 2 == 1){ TRUE } else { FALSE }
        bin.set(i, rem)
        num = num / 2
    }
    return Signal(bin)
}
/**
 * 'Add one' to an array of booleans, i.e. flip the lowest bit and
 * propagate the changes throughout the list
 * @param x The array of booleans
 */
func AddOne(x : Array<GateLevelValue>) : Unit {
    for (i in 0..(x.size - 1)) {
        if (x[i].IsTrue()) {
            x[i] = FALSE
        } else {
            x[i] = TRUE
            return
        }
    }
}
/**
 * Invert an array of bools, i.e. flip each bit
 * @param x The array of booleans
 */
func Invert(x : Array<GateLevelValue>) : Unit {
    for (i in 0..(x.size)){
        x[i] = x[i].Negate()
    }
}
/**
 * Convert a decimal number to a bitstring of a fixed length,
 * interpreted as an array of booleans
 * @param x The number to convert
 * @param w The width of the bitstring
 * @return The corresponding bitstring
 */
func SignedDecToBin(x : Int64, w : Int64) : Signal<GateLevelValue> {
    let bin = UnsignedDecToBin(abs(x), w).values
    Invert(bin)
    AddOne(bin)
    Signal(bin)
}
/**
 * Use an unsigned value for a given number
 * @param x The number to convert
 * @param width The width of the resulting bitstring
 * @return The wire of the value
 */
public func UseUnsignedSignalFromInt(x : Int64, width!: Int64) : BelnapWire {
    let bin = UnsignedDecToBin(x, width)
    UseSignal(bin)
}
/**
 * Use a signed value for a given number
 * @param x The number to convert
 * @param width The width of the resulting bitstring
 * @return The wire of the value
 */
public func UseSignedSignalFromInt(x : Int64, width!: Int64) : BelnapWire {
    let bin = SignedDecToBin(x, width)
    UseSignal(bin)
}
/**
 * Use a value for a given number
 * @param x The number to convert
 * @param signed Whether the number is signed or not
 * @param width The width of the resulting bitstring
 * @return The wire of the value
 */
public func UseSignalFromInt(
    x : Int64,
    signed: Bool,
    width!: Int64
) : BelnapWire {
    if(signed){
        UseSignedSignalFromInt(x, width: width)
    } else {
        UseUnsignedSignalFromInt(x, width: width)
    }
}
/**
 * Create a zero value for a given width, i.e. all falses
 * @param width The width of the bitstring
 * @return The wire of the value
 */
public func Zero(width: Int64) : BelnapWire {
    let values = Array<GateLevelValue>(width, { i : Int64 => FALSE })
    UseSignal(Signal(values))
}
/**
 * Create a constant zero waveform for a given width, i.e. all falses
 * @param width The width of the bitstring
 * @return The wire of the value
 */
public func ConstantZero(width: Int64) : BelnapWire {
    let signal = GetSignal(FALSE, width)
    UseInfiniteWaveform(signal)
}
/**
 * Create a constant zero waveform for one bit, i.e. a false
 * @return The wire of the value
 */
public func ConstantZero() : BelnapWire {
    ConstantZero(1)
}
/**
 * Perform an unsigned extension on a wire, i.e. add a false as its msb
 * @param w The input wire
 * @return The wire with an extra bit
 */
public func UnsignedExtend(
    w : BelnapWire
) : BelnapWire {
    let waveform = UseInfiniteWaveform<GateLevelValue, GateLevelPrimitive>(Signal([FALSE]))
    Combine([waveform, w])
}

public func MakeWaveform(
    vs : Array<Int64>,
    wfType : WaveformType,
    width!: Int64,
    signed!: Bool = true
) : BelnapCircuit {
    let signals = map({v : Int64 => DecToBin(v, width, signed) }, vs)
    MakeWaveform(Waveform(signals), wfType)
}