package hypergraphs

import debug.*

func DecToBin(w : Int64, x : Int64, signed: Bool){
    if(w < 1){
        throw NotEnoughBitsException("DecToBin")
    }
    var num = signed ? x < 0 ? x + (2 ** w) : x : x
    let bin = ArrayList<Bool>(w, {x : Int64 => false})

    for(i in 0..w-1){
        let rem = num % 2 == 1
        bin.set(i, rem)
        num = num / 2
    }
    if(signed && x < 0){
        bin.set(w-1, true)
    }
    return bin
}

/**
 * Create a tensor of values from an int
 * This tensor is ordered with the lsb at the top
 * e.g. 10 => 0 * 1 * 0 * 1
 * If the value is required to be signed, will be encoded in twos complement
 * @param x      The number to create a value for
 * @param width  The width of the bus to create
 * @param signed Whether the number is signed  or not
 * @param name   The name to assign the value
 */
func ValueFromInt(x : Int64, width!: Int64, signed!: Bool, name!: String = ""){
    let bin = DecToBin(width, x, signed)
    let values : ArrayList<Hypergraph> = map(bin, {b : Bool => b ? True() : False()})
    return Par(values, name: name)
}

external func SignedValueFromInt(x : Int64, width!: Int64, name!: String = ""){
    Debug("SignedValueFromInt", "Creating signed value for ${x} of width ${width}")
    ValueFromInt(x, width: width, signed: true, name: name) 
}
external func UnsignedValueFromInt(x : Int64, width!: Int64, name!: String = ""){
    Debug("UnsignedValueFromInt", "Creating unsigned value for ${x} of width ${width}")
    ValueFromInt(x, width: width, signed: false, name: name) 
}

external func Zero(width!: Int64 = 1){
    Debug("Zero", "Creating zero value of width ${width}")
    if(width < 1){
        throw NotEnoughBitsException("Zero")
    }
    Par(False(), width)
}