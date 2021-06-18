/**
 * buses.cj
 *
 * This file contains definitions of wires and buses that can be assigned to sources
 */
package circuits

import debug.*

/** 
 * Keep track of all the buses defined
 * Avoids accidental redefinition of buses
 */
var usedBusNames = MapBuilder<String, Bus>()
var globalBusList = ArrayList<Bus>()
/**
 * A bus is a bundle of wires with a name
 */
class Bus <: Identifiable {
    let name : Option<String>
    let wires = ArrayList<Wire>()
    private let wireMap = MapBuilder<Int64, Wire>()
    init() {
        this("")
    }
    init(name : String) {
        if(name == ""){
            this.name = None<String>
        } else {
            this.name = name
            let a = usedBusNames.add(name, this)
        }
        globalBusList.add(this)
    }
    /**
     * Get an identifier for this bus
     */
    func GetName(){
        match(name){
            case Some(str) => str
            case $None => "b${id}"
        }
    }
    /**
     * Add a wire to the bundle of wires and get its position
     * @return The position of the new wire in the bundle
     */
    func AddWire(wire : Wire){
        wireMap.add(wire.i, wire)
        InsertWire(wire)
    }
    /**
     * Get a given wire from this bus
     * Returns None if this wire does not exist
     * @param i The index of the wire to get
     */
    func GetWire(i : Int64){
        wireMap.toMap().get(i)
    }
    /** 
     * Insert a wire into the list at the appropriate position based on its index
     * @param wire the wire
     */
    func InsertWire(wire : Wire){
        for(i in 0..wires.size()){
            if(wire.i < wires[i].i){
                wires.add(i, wire)
                return
            }
            if(wire.i == wires[i].i){
                throw DuplicateWireException("InsertWire", this, wire.i)
            }
        }
        wires.add(wire)
    }
    func GetString(){
        let res = match(name){
            case Some(str) => str
            case $None      => "b${id}"
        }
        "bus ${res}"
    }
}
extend Bus <: ToString {
    func toString(){
        this.GetString()
    }
}
extend Bus <: Equatable {
    operator func ==(rhs : Bus) : Bool { 
        match(this.name){
            case Some(str1) =>
                match(rhs.name) {
                    case Some(str2) => str1 == str2
                    case $None => this.id == rhs.id 
                }
            case $None => this.id == rhs.id
        }
    }   
    operator func !=(rhs : Bus) : Bool { !(this == rhs) }
}
// extend Bus <: Hashable {
//     func hashCode() : UInt64 { 
//         match(this.name){
//             case Some(str) => str.hashCode() * 10 + 1
//             case $None     => this.id * 10
//         }
//      }
// }
/**
 * Get the existing bus that corresponds to a given string
 * @param string the name of the bus
 * @return The corresponding bus, or None if it doesn't exist
 */ 
func GetBusOption(string: String){
    if(string == ""){
        None<Bus>
    } else {
        usedBusNames.toMap().get(string)
    }
}
/**
 * Get the existing bus that corresponds to a given string
 * Throws an exception if the bus doesn't exist
 * @param string the name of the bus
 * @return The corresponding bus
 */ 
func GetBus(string : String){
    match(GetBusOption(string)){
        case Some(b) => b
        case $None   => throw NoSuchBusException("GetBus", string)
    }
}
/**
 * Find a bus with a a given name, and creates it if it doesn't exist
 * @param string the name of the bus
 * @return The corresponding bus, which may be fresh if it didn't exist previously
 */ 
func FindBus(string : String){
    match(GetBusOption(string)){
        case Some(b) => b
        case $None   => NewBus(string)
    }
}
/**
 * Create a new bus
 * @return The new bus
 */
func NewBus() : Bus {
    NewBus("")
}
/**
 * Create a new bus with a given name
 * Throws an exception if this bus already exists
 * @param string the name of the bus
 * @return The new bus
 */
func NewBus(string: String) : Bus {
    if(string == ""){
        return Bus()
    } 
    let bus = match(GetBusOption(string)){
        case Some(b) => throw DuplicateBusException("NewBus", string)
        case $None   => Bus(string)
    }
    bus
}
/**
 * A wire corresponds to one vertex in the graph
 * It has a parent bus and the position it occupies in that bus
 */
class Wire <: Atom {
    let bus : Bus
    let i : Int64
    init(bus: Bus, i : Int64){
        this.bus = bus
        this.i = i
        bus.AddWire(this)
    }
    init(){
        this.bus = NewBus()
        this.i = 0
        bus.AddWire(this)
    }
    func GetString(){
        let name = match(bus.name){
            case Some(name) => name
            case $None      => "b${bus.id}"
        }
        "${name}[${i}]"
    }
}
/**
 * Create a new wire at a given index of a bus
 * Throws an exception if this wire already exists
 * @param bus The bus to add the wire to
 * @param i   The index to add the wire to
 * @return The new wire
 */
func NewWire(bus : Bus, i : Int64) : Wire {
    if(i < 0){
        throw NegativeWireException("NewWire")
    }
    match(bus.GetWire(i)){
        case Some(w) => throw DuplicateWireException("NewWire", bus, i)
        case $None   => Wire(bus, i)
    }
}
/**
 * Create a new wire at a given index of a bus with a name
 * If the bus does not exist, creates it first
 * Throws an exception if this wire already exists
 * @param string The name of the bus to add the wire to
 * @param i      The index to add the wire to
 * @return The new wire
 */
func NewWire(string : String, i : Int64) : Wire {
    let b = GetBusOption(string)
    match(b) {
        case Some(bus) => NewWire(bus, i) 
        case $None     => NewWire(Bus(string), i)
    }
}
/**
 * Create a new wire at the next available index of a bus
 * Throws an exception if this wire already exists
 * @param bus The bus to add the wire to
 * @return The new wire
 */
func NewWire(bus : Bus){
    for(i in 0..bus.wires.size()){
        match(bus.GetWire(i)){
            case Some(w) => {}
            case $None   => return NewWire(bus, i)
        }
    }
    return NewWire(bus, bus.wires.size())
}
/**
 * Create a new wire at the next available index of a bus with a name
 * If the bus does not exist, creates it first
 * Throws an exception if this wire already exists
 * @param string The name of the bus to add the wire to
 * @return The new wire
 */
func NewWire(string : String) : Wire {
    let b = GetBusOption(string)
    match(b) {
        case Some(bus) => NewWire(bus)
        case $None     => NewWire(Bus(string), 0)
    }
}
/**
 * Create a new wire in a new bus
 * @return The new wire
 */
func NewWire() : Wire {
    NewWire("")
}

/**
 * Pretty print a list of wires
 * @param ws The list of wires
 * @return The pretty printed list of wires
 */
func WireListToString(ws : ArrayList<Wire>){
    PrintList(ws, {w : Wire => "${w}"})
}