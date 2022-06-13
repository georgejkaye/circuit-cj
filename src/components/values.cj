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
func UnsignedDecToBin(x : Int64, w : Int64) : ArrayList<Bool> {
    if(x < 0){
        throw NegativeNumberException("DecToBin", x)
    }
    let required = log2Ceil(x+1)
    if(required > w) {
        throw NotEnoughBitsException("UnsignedDecToBin", x, w, required)
    }
    // Set up the list
    let bin = ArrayList<Bool>(w, {x : Int64 => false})
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

func AddOne(x : ArrayList<Bool>) : Unit {
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

func Invert(x : ArrayList<Bool>) : Unit {
    for (i in 0..(x.size())){
        x[i] = !x[i]
    }
}

func SignedDecToBin(x : Int64, w : Int64) : ArrayList<Bool> {
    let bin = UnsignedDecToBin(abs(x), w)
    Invert(bin)
    AddOne(bin)
    bin
}

public func ValueStack(vs : ArrayList<Value>){
    let edges = map(
        { v : Value => Edge(VALUE(v))},
        vs
    )
    let compressor = Edge(COMPRESSOR(vs.size(), 1)) 
    let vertices = map(
        { v : Value => Vertex() },
        vs
    )
    let x : Unit = foldi_left(
        { acc : Unit, e : Edge , i : Int64 => 
            let v = vertices[i]
            e.SetTarget(0, v)
            compressor.SetSource(i, v)    
        },
        (),
        edges
    )
    let outVertex = Vertex(vs.size())
    vertices.add(outVertex)
    compressor.SetTarget(0, outVertex)
    edges.add(compressor)
    
    Hypergraph(HashSet<Vertex>(vertices), HashSet<Edge>(edges), ArrayList<Vertex>(), ArrayList<Vertex>([outVertex]))
}

public func ValueStack(vs : ArrayList<Bool>) {
    ValueStack(
        map(
            { b : Bool => if (b) { True } else { False } },
            vs
        )
    )
}

public func UnsignedValueFromInt(x : Int64, width: Int64) : Vertex {
    let bin = UnsignedDecToBin(x, width)
    ValueStack(bin).GetOutputVertices()[0]
}

public func SignedValueFromInt(x : Int64, width: Int64) : Vertex {
    let bin = SignedDecToBin(x, width)
    ValueStack(bin).GetOutputVertices()[0]
}