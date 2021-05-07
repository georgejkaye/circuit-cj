package hypergraphs

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
class Bus <: Atom {
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
     * Add a wire to the bundle of wires and get its position
     * @return The position of the new wire in the bundle
     */
    func AddWire(wire : Wire){
        Debug("AddWire", "Adding wire ${wire.i} to ${this}")
        wireMap.add(wire.i, wire)
        InsertWire(wire)
    }

    func GetWire(i : Int64){
        wireMap.toMap().get(i)
    }

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
}
append Bus with ToString, Equatable, Hashable {
    func toString(b : Bus){
        let name = match(b.name){
            case Some(name) => name
            case $None      => "b${b.id}"
        }
        "bus ${name}"
    }
    operator func ==(lhs : Bus, rhs : Bus) : Bool { 
        match(lhs.name){
            case Some(str1) => {
                match(rhs.name) {
                    case Some(str2) => str1 == str2
                    case $None => lhs.id == rhs.id 
                }
            }
            case $None => lhs.id == rhs.id
        }
    }   
    operator func !=(lhs : Bus, rhs : Bus) : Bool { !(lhs == rhs) }
    func hashCode(b : Bus) : UInt64 { 
        match(b.name){
            case Some(str) => hashCode(str) * 10 + 1
            case $None     => b.id * 10
        }
     }
}

func GetBusOption(string: String){
    if(string == ""){
        None<Bus>
    } else {
        usedBusNames.toMap().get(string)
    }
}

func GetBus(string : String){
    match(GetBusOption(string)){
        case Some(b) => b
        case $None   => throw NoSuchBusException("GetBus", string)
    }
}

func FindBus(string : String){
    match(GetBusOption(string)){
        case Some(b) => b
        case $None   => NewBus(string)
    }
}

func NewBus() : Bus {
    NewBus("")
}

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
}
append Wire with ToString, Equatable {
    func toString(w : Wire){
        let name = match(w.bus.name){
            case Some(name) => name
            case $None      => "b${w.bus.id}"
        }
        "${name}[${w.i}]"
    }
    operator func ==(lhs : Wire, rhs : Wire) : Bool { lhs.bus == rhs.bus && lhs.i == rhs.i }
    operator func !=(lhs : Wire, rhs : Wire) : Bool { lhs.id != rhs.id || lhs.i != rhs.i }
}

func NewWire(bus : Bus, i : Int64) : Wire {
    if(i < 0){
        throw NegativeWireException("NewWire")
    }
    match(bus.GetWire(i)){
        case Some(w) => throw DuplicateWireException("NewWire", bus, i)
        case $None   => Wire(bus, i)
    }
}

func NewWire(string : String, i : Int64) : Wire {
    let b = GetBusOption(string)
    match(b) {
        case Some(bus) => NewWire(bus, i) 
        case $None     => NewWire(Bus(string), i)
    }
}

func NewWire(bus : Bus){
    for(i in 0..bus.wires.size()){
        match(bus.GetWire(i)){
            case Some(w) => {}
            case $None   => return NewWire(bus, i)
        }
    }
    return NewWire(bus, bus.wires.size())
}

func NewWire(string!: String = "") : Wire {
    let b = GetBusOption(string)
    match(b) {
        case Some(bus) => NewWire(bus)
        case $None     => NewWire(Bus(), 0)
    }
}

func WireListToString(ws : ArrayList<Wire>){
    var str = "["
    for(w in ws){
        str = "${str} ${w}"
    }
    str = "${str} ]"
    str
}