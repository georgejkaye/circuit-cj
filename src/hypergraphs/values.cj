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
        bin.set(w-i-1, rem)
        num = num / 2
    }
    if(signed && x < 0){
        bin.set(0, true)
    }
    return bin
}

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