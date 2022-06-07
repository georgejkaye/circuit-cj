/**
 * generators.cj
 *
 * This file contains the definition of generators (in the free categorical sense)
 * and also defines preset generators for the user
 */

package syntax

from std import collection.ArrayList

public interface InputOutput {
    func GetInputs() : Int64
    func GetOutputs() : Int64
}

public interface Nameable {
    func GetName() : String
}

public interface Specifiable <: Nameable & InputOutput {
}

public enum Value { None | False | True | Both }
extend Value <: ToString & Specifiable {
    public func toString() : String {
        match(this) {
            case None => "⊥"
            case False => "f"
            case True => "t"
            case Both => "⊤"
        }
    }
    public func GetInputs() : Int64 {
        0
    }
    public func GetOutputs() : Int64 {
        1
    }
    public func GetName() : String {
        this.toString()
    }
}

/**
 * There are three types of structural morphisms to fork, join and stub wires
 */

public enum Structural { Fork | Join | Stub }
extend Structural <: ToString & Specifiable {
    public func toString() : String {
        match(this) {
            case Fork => "fork"
            case Join => "join"
            case Stub => "stub"
        }
    }
    public func GetInputs() : Int64 {
        match(this) {
            case Fork => 1
            case Join => 2
            case Stub => 1
        }
    }
    public func GetOutputs() : Int64 {
        match(this) {
            case Fork => 2
            case Join => 1
            case Stub => 0
        }
    }
    public func GetName() : String {
        this.toString()
    }
}

/**
 * Interfaces have a name, domain and codomain
 * (Gates are a special case in which codomain is 1)
 */
public class Specification <:ToString & Equatable<Specifiable> & Specifiable {
    let name : String
    let dom : Int64
    let cod : Int64
    init(name : String, dom : Int64, cod : Int64) {
        this.name = name
        this.dom = dom
        this.cod = cod
    }
    public func toString() : String {
        "${name} : ${dom} → ${cod}" 
    }
    public operator func ==(rhs: Specifiable) : Bool {
        this.name == rhs.GetName() && this.dom == rhs.GetInputs() && this.cod == rhs.GetOutputs()
    }
    public operator func !=(rhs: Specifiable) : Bool { 
        !(this == rhs) 
    }
    public func GetName() : String {
        this.name
    }
    public func GetInputs() : Int64 {
        this.dom
    }
    public func GetOutputs() : Int64 {
        this.cod
    }
}

public class GateSpecification <: ToString & Equatable<Specifiable> & Specifiable {
    let spec : Specification
    init (name : String, dom : Int64) {
        this.spec = Specification(name, dom, 1)
    }
    public func toString() : String {
        this.spec.toString()
    }
    public operator func ==(rhs: Specifiable) : Bool {
        this.spec == rhs
    }
    public operator func !=(rhs: Specifiable) : Bool { 
        !(this == rhs) 
    }
    public func GetInputs() : Int64 {
        this.spec.GetInputs()
    }
    public func GetOutputs() : Int64 {
        this.spec.GetOutputs()
    }
    public func GetName() : String {
        this.spec.GetName()
    }
}

public class LinkKey <: Identifiable & Nameable & Equatable<LinkKey> & ToString {
    let uniqueId : Identifier
    let name : String
    init(name : Option<String>) {
        let id = Identifier()
        this.name = name.getOrDefault({ => "${id.GetId()}" })
        this.uniqueId = id
    }
    public func GetName() : String {
        this.name
    }
    public func GetId() : Int64 {
        this.uniqueId.GetId()
    }
    public operator func ==(rhs : LinkKey) : Bool {
        this.uniqueId == rhs.uniqueId
    }
    public operator func !=(rhs : LinkKey) : Bool {
        !(this == rhs)
    }
    public func toString() : String {
        "Link key - ${name}"
    }
}

/**
 * A link contains information about a link
 * It has an id, a name, and a width 
 */
public class InLinkSpecification <: Equatable<Specifiable> & ToString & Specifiable {
    let key : LinkKey
    let spec : Specification
    init(key : LinkKey, width : Int64) {
        this.key = key
        this.spec = Specification(key.GetName(), 0, width)
    }
    public operator func ==(rhs : Specifiable) : Bool {
        this.spec == rhs
    }
    public operator func !=(rhs : Specifiable) : Bool {
        !(this == rhs)
    }
    public func toString() : String {
        "In link - ${this.spec.GetName()} width ${this.spec.GetOutputs()}"
    }
    public func GetName() : String {
        this.spec.GetName()
    }
    public func GetInputs() : Int64 {
        this.spec.GetInputs()
    }
    public func GetOutputs() : Int64 {
        this.spec.GetOutputs()
    }
}

public class OutLinkSpecification <: Equatable<Specification> & ToString & InputOutput {
    let key : LinkKey
    let spec : Specification
    init(key : LinkKey, width : Int64) {
        this.key = key
        this.spec = Specification(key.GetName(), width, 0)
    }
    public operator func ==(rhs : Specification) : Bool {
        this.spec == rhs
    }
    public operator func !=(rhs : Specification) : Bool {
        !(this == rhs)
    }
    public func toString() : String {
        "Out link - ${this.spec.GetName()} width ${this.spec.GetInputs()}"
    }
    public func GetName() : String {
        this.spec.GetName()
    }
    public func GetInputs() : Int64 {
        this.spec.GetInputs()
    }
    public func GetOutputs() : Int64 {
        this.spec.GetOutputs()
    }
}

/**
 * Enum for the different types of generators
 */
public enum Label { 
    | VALUE(Value)            // A value 0 -> 1
    | STRUCTURAL(Structural)  // A structural generator 
    | GATE(GateSpecification)         // A gate m -> 1
    | BLACKBOX(Specification)     // A black box with arbitrary name and codomain
    | DELAY(Int64)           // A delay parameterised by a duration
    | IDENTITY                // An identity 1 -> 1
    | INLINK(InLinkSpecification)            // An in-link 0 -> m, where wires come into the graph
    | OUTLINK(OutLinkSpecification)           // An out-link m -> 0, where wires come out of the graph
}
extend Label <: ToString & InputOutput {
    public func toString() : String {
        match(this){
            case VALUE(value)        => "value (${value})"
            case STRUCTURAL(struc)  =>  "structural (${struc})"
            case GATE(spec)         => "gate (${spec.GetName()})"
            case BLACKBOX(spec)     => "black box (${spec.GetName()})"
            case DELAY(dur)          => "delay (${dur})"
            case IDENTITY           =>  "identity"
            case INLINK(link)        => "in link (${link.GetName()} - ${link.GetOutputs()})"
            case OUTLINK(link)       => "out link (${link.GetName()} - ${link.GetInputs()})"
        }
    }
    public func GetInputs() : Int64 {
        match(this) {
            case VALUE(value)       => 0
            case STRUCTURAL(struc)  => struc.GetInputs()
            case GATE(spec)         => spec.GetInputs() 
            case BLACKBOX(spec)     => spec.GetInputs()
            case DELAY(dur)         => 1 
            case IDENTITY           => 1
            case INLINK(link)       => 0
            case OUTLINK(link)      => link.GetInputs()
        }
    }
    public func GetOutputs() : Int64 {
        match(this) {
            case VALUE(value)       => 1
            case STRUCTURAL(struc)  => struc.GetOutputs()
            case GATE(spec)         => spec.GetOutputs() 
            case BLACKBOX(spec)     => spec.GetOutputs()
            case DELAY(dur)         => 1 
            case IDENTITY           => 1
            case INLINK(link)       => link.GetOutputs()
            case OUTLINK(link)      => 0
        }
    }
}