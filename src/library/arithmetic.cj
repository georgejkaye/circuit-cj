package library

import hypergraphs.*

func DecToBin(w : Int64, x : Int64){
    if(w < 1){
        throw NotEnoughBitsException()
    }
    var num = x < 0 ? x + (2 ** w) : x
    let bin = ArrayList<Bool>(w, {x : Int64 => false})

    for(i in 0..w-1){
        let rem = num % 2 == 1
        bin.set(w-i-1, rem)
        num = num / 2
    }
    if(x < 0){
        bin.set(0, true)
    }
    return bin
}

external func ValueFromInt(x : Int64, width!: Int64){
    let bin = DecToBin(width, x)
    for(b in bin){
        print(b ? "1" : "0")
    }
    print("\n")
    let values : ArrayList<Hypergraph> = map(bin, {b : Bool => b ? True() : False()})
    return Par(values)
}