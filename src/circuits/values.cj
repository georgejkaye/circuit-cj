/**
 * values.cj
 *
 * This file contains functions to construct values (circuits of form 0->n)
 */

package circuits

import debug.*

/**
 * Convert a decimal number to a list of truth values
 * The list is ordered with the lsb first
 * e.g. 10 => [0, 1, 0, 1, 0, ...]
 * If signed, the negative numbers are represented in twos complement
 * @param w      The width of the resulting list
 * @param x      The decimal number to convert
 * @param signed If the number must be signed
 */
func DecToBin(w : Int64, x : Int64, signed: Bool){
    if(w < 1){
        throw NotEnoughBitsException("DecToBin")
    }
    if(!signed && x < 0){
        throw NegativeNumberException("DecToBin", x)
    }
    // If the number is signed, we add 2^width to it
    var num = if (signed && x < 0) { x + (2 ** w) } else { x }
    // Set up the list
    let bin = ArrayList<Bool>(w, {x : Int64 => false})
    // Divide by two w times, setting the remainder to the ith bit of the list
    // If we run out of w before we run out of list, the msbs will be ignored
    for(i in 0..w){
        let rem = num % 2 == 1
        bin.set(i, rem)
        num = num / 2
    }
    // We need to flip the first bit of negative signed numbers
    if(signed && x < 0){
        bin.set(w-1, true)
    }
    return bin
}

/**
 * Create a stack of values tensored together
 * @param vs     The list of values
 * @param label  The wire label to assign the outputs
 * @return The tensor stack graph
 */
func ValueStack(vs : ArrayList<Value>, label!: String = ""){
    let hb = HypBuilder(0, vs.size(), label)
    // For each value, create an edge for it and set it to point to the outputs
    for(i in 0..vs.size()){
        hb.CreateEdge(VALUE(vs[i]), [], [hb.GetOutputs()[i]])
    }
    hb.ToGraph()
}

func ValueStack(v : Value, n : Int64, label!: String = ""){
    if(n < 1){
        throw NegativeWireException("ValueStack")
    }
    ValueStack(ArrayList<Value>(n, {x : Int64 => v}), label: label)
}

/**
 * Create a tensor of values from an int
 * This tensor is ordered with the lsb at the top
 * e.g. 10 => 0 * 1 * 0 * 1
 * If the value is required to be signed, will be encoded in twos complement
 * @param x      The number to create a value for
 * @param width  The width of the bus to create
 * @param signed Whether the number is signed or not
 * @param label  The wire name to associate with this value
 * @param name   The name to assign the value
 */
func ValueFromInt(x : Int64, width!: Int64, signed!: Bool, label!: String = "", name!: String = ""){
    let bin = DecToBin(width, x, signed)
    let values = map(bin, {b : Bool => if(b) { TRUE } else { FALSE } })
    ValueStack(values)
}
/**
 * Convert an in into a graph representing its signed value stack
 * @param x     The int to convert
 * @param width The width of the result
 * @param label The wire name to associate with this value
 * @param name  The name of the graph
 */
external func SignedValueFromInt(x : Int64, width!: Int64, label!: String = "", name!: String = ""){
    Debug("SignedValueFromInt", "Creating signed value for ${x} of width ${width}")
    ValueFromInt(x, width: width, signed: true, name: name) 
}
/**
 * Convert an in into a graph representing its unsigned value stack
 * @param x     The int to convert
 * @param width The width of the result
 * @param label The wire name to associate with this value
 * @param name  The name of the graph
 */
external func UnsignedValueFromInt(x : Int64, width!: Int64, label!: String = "", name!: String = ""){
    Debug("UnsignedValueFromInt", "Creating unsigned value for ${x} of width ${width}")
    ValueFromInt(x, width: width, signed: false, label: label, name: name) 
}
/**
 * Create a zero value for a given width (i.e. everything is false)
 * @param width The width of the stack
 * @return The w-width stack of false values
 */
external func Zero(width!: Int64 = 1, label!: String = ""){
    Debug("Zero", "Creating zero value of width ${width}")
    ValueStack(FALSE, width, label: label)
}
/**
 * Extend an unsigned value by one, by adding an extra False in front of it
 * @param v The value
 * @return The extended unsigned value
 */
external func UnsignedExtend(v: Hypergraph){
    let hb = v.Clone()
    let s = Source()
    hb.AddOutput(s)
    hb.CreateEdge(VALUE(FALSE), [], [s]) 
    hb.ToGraph()
}