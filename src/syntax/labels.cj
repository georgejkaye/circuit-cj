/**
 * generators.cj
 *
 * This file contains the definition of generators (in the free categorical sense)
 * and also defines preset generators for the user
 */

package syntax

from std import collection.ArrayList

public enum Value { None | False | True | Both }
extend Value <: ToString {
    public func toString() : String {
        match(this) {
            case None => "⊥"
            case False => "f"
            case True => "t"
            case Both => "⊤"
        }
    }
}

/**
 * There are three types of structural morphisms to fork, join and stub wires
 */

public enum Structural { Fork | Join | Stub }
extend Structural <: ToString {
    public func toString() : String {
        match(this) {
            case Fork => "fork"
            case Join => "join"
            case Stub => "stub"
        }
    }
}
/**
 * Interfaces have a name, domain and codomain
 * (Gates are a special case in which codomain is 1)
 */
public class Interface <: ToString & Equatable<Interface> {
    let name : String
    let dom : UInt64
    let cod : UInt64
    init(name : String, dom : UInt64, cod : UInt64) {
        this.name = name
        this.dom = dom
        this.cod = cod
    }
    public func toString() { "Label ${name} : ${dom} → ${cod}" }
    public operator func ==(rhs: Interface) : Bool { this.name == rhs.name && this.dom == rhs.dom && this.cod == rhs.cod }
    public operator func !=(rhs: Interface) : Bool { !(this == rhs) }
}

/**
 * A link contains information about a link
 * It has an id, a name, and a width 
 */
public class Link <: Identifiable & Equatable<Link> & ToString {
    let name : String
    let width : UInt64
    init(name : String, width : UInt64) {
        this.name = if(name == ""){
            "ls${super.id}"
        } else {
            name
        }
        this.width = width
    }
    init(width : UInt64) {
        this.name = "ls${super.id}"
        this.width = width
    }
    public operator func ==(rhs : Link){
        this.name == rhs.name && this.width == rhs.width
    }
    public operator func !=(rhs : Link){
        !(this == rhs)
    }
    public override func toString(){
        "Link - ${name} width ${width}"
    }
}

/**
 * Enum for the different types of generators
 */
public enum Label { 
    | VALUE(Value)            // A value 0 -> 1
    | STRUCTURAL(Structural)  // A structural generator 
    | GATE(Interface)         // A gate m -> 1
    | BLACKBOX(Interface)     // A black box with arbitrary name and codomain
    | DELAY(UInt64)           // A delay parameterised by a duration
    | IDENTITY                // An identity 1 -> 1
    | INLINK(Link)            // An in-link 0 -> m, where wires come into the graph
    | OUTLINK(Link)           // An out-link m -> 0, where wires come out of the graph
}
extend Label <: ToString {
    public func toString(){
        match(this){
            case VALUE(value)        => "value (${value})"
            case STRUCTURAL(struc)  =>  "structural (${struc})"
            case GATE(label)         => "gate (${label.name})"
            case BLACKBOX(label)     => "black box (${label.name})"
            case DELAY(dur)          => "delay (${dur})"
            case IDENTITY           =>  "identity"
            case INLINK(link)        => "in link (${link.name} - ${link.width})"
            case OUTLINK(link)       => "out link (${link.name} - ${link.width})"
        }
    }
}
/** 
 * Get the domain and codomain of a label
 */
func GetDomCod(lab : Label) : (UInt64, UInt64) {
    match(lab){
        case VALUE(val)         => (0, 1)
        case STRUCTURAL(struc)  =>
            match(struc) {
                case Fork       => (1, 2)
                case Join       => (2, 1)
                case Stub       => (1, 0)
            }
        case GATE(label)        => (label.dom, label.cod)
        case BLACKBOX(label)    => (label.dom, label.cod)
        case DELAY(dur)         => (1, 1)
        case IDENTITY           => (1, 1)
        case INLINK(link)       => (0, link.width)
        case OUTLINK(link)      => (link.width, 0)
    }
}
/**
 * Get the domain of a generator
 */
func Dom(lab : Label){
    GetDomCod(lab)[0]
}
/**
 * Get the codomain of a generator
 */
func Cod(lab : Label){
    GetDomCod(lab)[1]
}