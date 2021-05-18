/**
 * bits.cj
 * 
 * This file contains components to manipulate bits
 */

package hypergraphs

import debug.*

/**
 * Make a construct that exposes a given bit from its inputs and drops the rest
 * @param w The number of inputs to the construct
 * @param n The bit to expose
 * @return A construct that exposes the nth bit of a w-size bus and drops the rest
 */
func GetBit(w : Int64, n : Int64){
    if(w < n || n < 0 || w < 1) {
        throw NotEnoughBitsException("GetBit (w=${w} n=${n})")
    }
    let f = {i : Int64, hb : HypBuilder, s : Source => 
        if(i == n) {
            hb.outputs.add(s)
        } else {
            hb.edges.add(Edge(STUB, [s], []))
        }
    }
    ForEachBit(w, f)
}

/**
 * Make a construct that drops a given bit from its inputs
 * @param w The number of inputs to the construct
 * @param n The bit to drop
 * @return A construct that drops the nth bit of a w-size bus
 */
func DropBit(w : Int64, n : Int64){
    if(w < n || n < 0 || w < 1){
        throw NotEnoughBitsException("DropBit (w=${w} n=${n})")
    }
    let f = {i : Int64, hb : HypBuilder, s : Source => 
        if(i == n){
            hb.edges.add(Edge(STUB, [s], []))
        } else {
            hb.outputs.add(s)
        }
    }
    ForEachBit(w, f)
}

/**
 * Make a construct with a bespoke action performed for each input bit
 * @param w      The number of inputs to the construct
 * @param f      The action to perform for each input
 * @param output The wire name to associate with the outputs of this construct
 * @return A construct that does the given action for each of its w inputs
 */
func ForEachBit(w : Int64, f : (Int64, HypBuilder, Source) -> Unit, output!: String = ""){
    if(w < 1){
        throw NotEnoughBitsException("ForEachBit")
    }
    let hb = HypBuilder()
    let bus = NewBus(output)
    for(i in 0..w){
        let t = Target()
        let s = Source(NewWire(bus))
        hb.inputs.add(t)
        hb.AddConn(t, s)
        f(i, hb, s)
    }
    hb.ToGraph()
}
/**
 * Get the most significant output from a hypergraph (output n-1)
 * @param f the hypergraph
 * @return The hypergraph with its most significant bits [1..n-1] exposed
 */
external func Msb(f: Hypergraph){
    Debug("Msb", "Getting the most significant bit from ${f.GetName()}")
    match(f.GetN()){
        case 0 => throw NotEnoughBitsException("Msb")
        case 1 => f
        case _ => Get(f, f.GetN() - 1)
    }
}
/**
 * Create a construct that gets the most significant bit of inputs of a given width
 * @param w The width of the construct
 * @return A construct that gets the most significant bit of its inputs (bit w-1)
 */
external func Msb(w : Int64){
    Debug("Msb", "Creating construct for most significant bit")
    match(w){
        case 0 => throw NotEnoughBitsException("Msb")
        case 1 => Identity(1)
        case _ => GetBit(w, w-1)
    }
}
/**
 * Get the most significant outputs from a hypergraph (outputs 1..n-1)
 * @param f the hypergraph
 * @return The hypergraph with its most significant bits [1..n-1] exposed
 */
external func Msbs(f: Hypergraph){
    Debug("Msbs", "Getting the most significant bits from ${f.GetName()}")
    match(f.GetN()){
        case 0 => throw NotEnoughBitsException("Msbs")
        case 1 => f
        case _ => Drop(f, 0)
    }
}
/**
 * Create a construct that gets the most significant bits of inputs of a given width
 * @param w The width of the construct
 * @return A construct that takes the most significant bits of its inputs (bits 1..w-1)
 */
external func Msbs(w: Int64){
    Debug("Msbs", "Creating construct for most significant bits")
    match(w){
        case 0 => throw NotEnoughBitsException("Msbs")
        case 1 => Identity(1)
        case _ => DropBit(w, 0)
    }
}
/**
 * Get the least significant bit of a hypergraph (output 0)
 * @param f the hypergraph
 * @return The hypergraph with only its least significant bit exposed.
 */
external func Lsb(f : Hypergraph){
    Debug("Lsb", "Getting the least significant bit from ${f.GetName()}")
    match(f.GetN()){
        case 0 => throw NotEnoughBitsException("Lsb")
        case 1 => f
        case _ => Get(f, 0)
    }
}
/**
 * Create a construct that gets the least significant bit of its inputs of a given width
 * @param w The number of inputs to the construct
 * @return A construct that gets the least significant bit of its inputs (bit 0)
 */
external func Lsb(w : Int64){
    Debug("Lsb", "Creating construct for least significant bit")
    match(w){
        case 0 => throw NotEnoughBitsException("Lsb")
        case 1 => Identity(1)
        case _ => GetBit(w, 0)
    }
}
/**
 * Get the least significant outputs from a hypergraph (outputs 0..n-2)
 * @param f the hypergraph
 * @return The hypergraph with its least significant bits [0..n-2] exposed
 */
external func Lsbs(f: Hypergraph){
    Debug("Lsbs", "Getting the least significant bits from ${f.GetName()}")
    match(f.GetN()){
        case 0 => throw NotEnoughBitsException("Lsbs")
        case 1 => f
        case _ => Drop(f, f.GetN() - 1)
    }
}
/**
 * Create a construct that gets the least significant bits of its inputs, and drops the most significant
 * @param w The number of inputs to the construct
 * @return A construct that drops the most significant bit of a w-size bus
 */
external func Lsbs(w : Int64){
    Debug("Lsbs", "Creating construct for least significant bits")
    match(w){
        case 0 => throw NotEnoughBitsException("Lsbs")
        case 1 => Identity(1)
        case _ => DropBit(w, w-1)
    }
}