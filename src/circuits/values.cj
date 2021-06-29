/**
 * values.cj
 *
 * This file contains functions to construct values (circuits of form 0->n)
 */

package circuits

import debug.*

/**
 * We use a value lattice with four values
 * ⊥ < t,f < ⊤
 */
enum Value { BOTTOM | TRUE | FALSE | TOP }
extend Value <: ToString { 
    func toString() : String {
        match(this){
            case $BOTTOM => "bot"
            case $TRUE   => "t"
            case $FALSE  => "f"
            case $TOP    => "top"
        }
    }
}
extend Value <: Equatable {
    operator func ==(rhs : Value) : Bool {
        match(this){
            case $BOTTOM =>
                match(rhs){
                    case $BOTTOM => true
                    case _ => false
                }
            case $TRUE => 
                match(rhs){
                    case $TOP => true
                    case _ => false
                }
            case $FALSE =>
                match(rhs){
                    case $FALSE => true
                    case _ => false
                }
            case $TOP =>
                match(rhs){
                    case $TOP => true
                    case _ => false
                }
        }
    }
    operator func !=(rhs : Value) { !(this == rhs) }
}
extend Value <: Hashable {
    func hashCode() : UInt64 {
        match(this) {
            case $BOTTOM => 0
            case $TRUE   => 1
            case $FALSE  => 2
            case $TOP    => 3
        }
    }
}
/**
 * Get the logical NOT of a values
 * @param v The argument
 * @return The logical AND of the argument
 */
func not(v : Value){
    match(v){
        case $TOP    => TOP
        case $BOTTOM => BOTTOM
        case $TRUE   => FALSE
        case $FALSE  => TRUE
    }
}
/**
 * Get the logical AND of two values
 * @param lhs The lhs argument
 * @param rhs The rhs argument
 * @return The logical AND of the two arguments
 */
func and(lhs : Value, rhs : Value){
    match(lhs){
        case $TOP    => TOP
        case $BOTTOM => BOTTOM
        case $TRUE   => rhs
        case $FALSE  => match(rhs){
                case $TOP    => TOP
                case $BOTTOM => BOTTOM
                case _       => FALSE
        }
    }
}
/**
 * Get the logical OR of two values
 * @param lhs The lhs argument
 * @param rhs The rhs argumnet
 * @return The logical OR of the two arguments
 */
func or(lhs : Value, rhs : Value){
    match(lhs){
        case $TOP    => TOP
        case $BOTTOM => BOTTOM
        case $FALSE   => rhs
        case $TRUE  => match(rhs){
                case $TOP    => TOP
                case $BOTTOM => BOTTOM
                case _       => TRUE
        }
    }
}
/**
 * Get the logical XOR of two values
 * @param lhs The lhs argument
 * @param rhs The rhs argumnet
 * @return The logical OR of the two arguments
 */
func xor(lhs : Value, rhs : Value){
    match(lhs){
        case $TOP    => TOP
        case $BOTTOM => BOTTOM
        case $FALSE   => rhs
        case $TRUE  => match(rhs){
                case $TOP    => TOP
                case $BOTTOM => BOTTOM
                case v       => not(v)
        }
    }
}
/**
 * Get the join of two values in the lattice
 * @param lhs The lhs argument
 * @param rhs The rhs argument
 * @return The join of the two values
 */
func join(lhs : Value, rhs : Value){
    match(lhs){
        case $TOP    => TOP
        case $BOTTOM => rhs
        case $TRUE   => match(rhs){
            case $TOP   => TOP
            case $FALSE => TOP
            case _      => TRUE
        }
        case $FALSE  => match(rhs){
            case $TOP   => TOP
            case $TRUE  => TOP
            case _      => FALSE
        }
    }
}
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
    hb
}
/**
 * Create a stack of the same value tensored together a given number of times
 * @param v      The value to stack
 * @param n      The number of times to stack the value
 * @param label  The wire label to assign the outputs
 * @return The tensor stack graph
 */
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
func CreateValueFromInt(x : Int64, width!: Int64, signed!: Bool, label!: String = "", name!: String = ""){
    let bin = DecToBin(width, x, signed)
    let values = map(bin, {b : Bool => if(b) { TRUE } else { FALSE } })
    ValueStack(values)
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
    CreateValueFromInt(x, width: width, signed: signed, label: label, name: name).ToGraph(name)
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
    ValueStack(FALSE, width, label: label).ToGraph()
}
/**
 * Extend an unsigned value by one, by adding an extra False in front of it
 * @param v The value
 * @return The extended unsigned value
 */
external func UnsignedExtend(v: Hypergraph){
    let hb = v.Clone()
    let f = hb.CreateEdge(VALUE(FALSE))
    let s = hb.NewOutput()
    hb.AddConn(f.targets[0], s) 
    hb.ToGraph()
}