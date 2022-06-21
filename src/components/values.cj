package components

from std import collection.ArrayList
from std import collection.HashSet

from std import math.abs

import prelude.*
import syntax.*
import graphs.*
import debug.*

func PadFront(xs : ArrayList<Bool>, width: Int64) : Unit {
    for (i in 0..(width - xs.size())){
        xs.prepend(false)
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
func UnsignedDecToBin(x : Int64, w : Int64) : Array<Bool> {
    if(x < 0){
        throw NegativeNumberException("DecToBin", x)
    }
    let required = log2Ceil(x+1)
    if(required > w) {
        throw NotEnoughBitsException("UnsignedDecToBin", x, w, required)
    }
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

func AddOne(x : Array<Bool>) : Unit {
    for (i in 0..(x.size()-1)) {
        let j = x.size() - 1 - i
        if (x[j]) {
            x[j] = false
        } else {
            x[j] = true
            return
        }
    }
}

func Invert(x : Array<Bool>) : Unit {
    for (i in 0..(x.size())){
        x[i] = !x[i]
    }
}

func SignedDecToBin(x : Int64, w : Int64) : Array<Bool> {
    let bin = UnsignedDecToBin(abs(x), w)
    Invert(bin)
    AddOne(bin)
    bin
}

public func MakeValue(vs : Array<Value>, signed : Bool) : WireEnd {
    let empty = Array<Vertex>()
    let value = Edge(VALUE(vs, signed), empty, [vs.size()])
    WireEnd(value.GetTarget(0))
}

public func MakeValue(vs : Array<Bool>, signed : Bool) {
    MakeValue(map({ b : Bool => if(b){ True } else { False }}, vs), signed)
}

public func UnsignedValueFromInt(x : Int64, width!: Int64) : WireEnd {
    let bin = UnsignedDecToBin(x, width)
    MakeValue(bin, false)
}

public func SignedValueFromInt(x : Int64, width!: Int64) : WireEnd {
    let bin = SignedDecToBin(x, width)
    MakeValue(bin, true)
}

public func Zero(width: Int64) {
    let values = Array<Value>(width){ i : Int64 => False }
    MakeValue(values, false)
}

public func ConstantZero(width: Int64) {
    let value = Zero(width)
    InfiniteWaveform(value)
}

public func UnsignedExtend(w : WireEnd) {
    let value = InfiniteWaveform(False)
    Combine([value, w])
}