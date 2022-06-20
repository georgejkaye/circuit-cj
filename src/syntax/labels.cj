/**
 * labels.cj
 *
 * This file contains the definition of generators (in the free categorical sense)
 */

package syntax

import prelude.*

from std import collection.ArrayList

public interface InputOutput {
    func GetInputs() : Int64
    func GetOutputs() : Int64
}

public interface Nameable {
    func GetName() : String
}

public interface Typeable {
    func GetInputType() : Array<Int64>
    func GetOutputType() : Array<Int64>
}

public interface Specifiable <: Nameable & Typeable {
}

public enum Value { Bottom | False | True | Top }
extend Value <: ToString {
    public func toString() : String {
        match(this) {
            case Bottom => "⊥"
            case False => "0"
            case True => "1"
            case Top => "⊤"
        }
    }
}

public func BitString(bits : Array<Value>) : String {
    fold_left({acc : String, v : Value => "${acc}${v}"}, "", bits)
}

public func PrintValue(vs : Array<Value>, signed : Bool, rep : NumberRepresentation) : String {
    match(rep) {
        case BIN => BitString(vs)
        case DEC =>
            var x = 0
            if (signed) {
                let negative = match(vs[0]) {
                    case Bottom => return BitString(vs)
                    case True => true
                    case False => false
                    case Top => return BitString(vs)
                }
                for (i in 0..vs.size()) {
                    var carry = true
                    match(vs[vs.size() - i - 1]) {
                        case Bottom => return BitString(vs)
                        case True => 
                            if(!carry) {
                                x += 2**i
                            }
                        case False => 
                            if(carry) {
                                x += 2**i
                                carry = false
                            }
                        case Top => return BitString(vs)
                    }
                }
            } else {
                for (i in 0..vs.size()) {
                    match(vs[i]) {
                        case Bottom => return BitString(vs)
                        case True   => x += 2**(vs.size() - 1 - i)
                        case False  => ()
                        case Top    => return BitString(vs)
                    }
                }
            }
            "${x}"
    }
}

/**
 * There are three types of structural morphisms to fork, join and stub wires
 */

public enum Structural { Fork | Join | Stub }
extend Structural <: ToString & InputOutput {
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
    let dom : Array<Int64>
    let cod : Array<Int64>
    public init(name : String, dom : Array<Int64>, cod : Array<Int64>) {
        this.name = name
        this.dom = dom
        this.cod = cod
    }
    public func toString() : String {
        "${name} : ${dom} → ${cod}" 
    }
    public operator func ==(rhs: Specifiable) : Bool {
        this.name == rhs.GetName() && this.dom == rhs.GetInputType() && this.cod == rhs.GetOutputType()
    }
    public operator func !=(rhs: Specifiable) : Bool { 
        !(this == rhs) 
    }
    public func GetName() : String {
        this.name
    }
    public func GetInputType() : Array<Int64> {
        this.dom
    }
    public func GetOutputType() : Array<Int64> {
        this.cod
    }
}

public class GateSpecification <: ToString & Equatable<Specifiable> & Specifiable {
    let spec : Specification
    init (name : String, inputs : Int64, width : Int64) {
        this.spec = Specification(name, Array<Int64>(inputs, { i : Int64 => width }), [width])
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
    public func GetInputType() : Array<Int64> {
        this.spec.GetInputType()
    }
    public func GetOutputType() : Array<Int64> {
        this.spec.GetOutputType()
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
        this.spec = Specification(key.GetName(), [], [width])
    }
    public operator func ==(rhs : Specifiable) : Bool {
        this.spec == rhs
    }
    public operator func !=(rhs : Specifiable) : Bool {
        !(this == rhs)
    }
    public func toString() : String {
        "In link - ${this.spec.GetName()} width ${this.spec.GetOutputType()}"
    }
    public func GetName() : String {
        this.spec.GetName()
    }
    public func GetInputType() : Array<Int64> {
        this.spec.GetInputType()
    }
    public func GetOutputType() : Array<Int64> {
        this.spec.GetOutputType()
    }
}

public class OutLinkSpecification <: Equatable<Specification> & ToString & InputOutput {
    let key : LinkKey
    let spec : Specification
    init(key : LinkKey, width : Int64) {
        this.key = key
        this.spec = Specification(key.GetName(), [width], [])
    }
    public operator func ==(rhs : Specification) : Bool {
        this.spec == rhs
    }
    public operator func !=(rhs : Specification) : Bool {
        !(this == rhs)
    }
    public func toString() : String {
        "Out link - ${this.spec.GetName()} width ${this.spec.GetInputType()}"
    }
    public func GetName() : String {
        this.spec.GetName()
    }
    public func GetInputType() : Array<Int64> {
        this.spec.GetInputType()
    }
    public func GetOutputType() : Array<Int64> {
        this.spec.GetOutputType()
    }
    public func GetInputs() : Int64 {
        this.spec.GetInputType()[0]
    }
    public func GetOutputs() : Int64 {
        this.spec.GetOutputType()[0]
    }
}

/**
 * Enum for the different types of generators
 */
public enum Label { 
    | VALUE(Array<Value>, Bool)           // A value 0 -> n, which could be signed or unsigned
    | BUNDLER(Array<Int64>, Array<Int64>) // A bundler changes how wires are bundled
    | JOIN(Int64)                         // Join two wires together
    | GATE(GateSpecification)             // A gate m -> 1
    | BLACKBOX(Specification)             // A black box with arbitrary name and codomain
    | DELAY(Int64, Int64)                 // A delay parameterised by a duration and a width
    | IDENTITY                            // An identity 1 -> 1
    | INLINK(InLinkSpecification)         // An in-link 0 -> m, where wires come into the graph
    | OUTLINK(OutLinkSpecification)       // An out-link m -> 0, where wires come out of the graph
}
extend Label <: ToString & Nameable {
    public func toString() : String {
        match(this){
            case VALUE(values, signed)  => "value (${values}), ${if(!signed){"un"}}signed"
            case BUNDLER(ms,ns)         => "bundler ${ms} to ${ms}"
            case JOIN(width)            => "join ${width}"
            case GATE(spec)             => "gate (${spec.GetName()})"
            case BLACKBOX(spec)         => "black box (${spec.GetName()})"
            case DELAY(dur, width)      => "delay (${dur}) width ${width}"
            case IDENTITY               => "identity"
            case INLINK(link)           => "in link (${link.GetName()} - ${link.GetOutputType()[0]})"
            case OUTLINK(link)          => "out link (${link.GetName()} - ${link.GetInputType()[0]})"
        }
    }
    public func GetInputType() : Array<Int64> {
        match(this) {
            case VALUE(values,signed)   => []
            case BUNDLER(ms,ns)         => ms
            case JOIN(width)            => [width,width]
            case GATE(spec)             => spec.GetInputType() 
            case BLACKBOX(spec)         => spec.GetInputType()
            case DELAY(dur, width)      => [width] 
            case IDENTITY               => [1]
            case INLINK(link)           => []
            case OUTLINK(link)          => link.GetInputType()
        }
    }
    public func GetOutputType() : Array<Int64> {
        match(this) {
            case VALUE(values,signed)   => [values.size()]
            case BUNDLER(ms,ns)         => ns
            case JOIN(width)            => [width]
            case GATE(spec)             => spec.GetOutputType() 
            case BLACKBOX(spec)         => spec.GetOutputType()
            case DELAY(dur, width)      => [width]
            case IDENTITY               => [1]
            case INLINK(link)           => link.GetOutputType()
            case OUTLINK(link)          => []
        }
    }
    public func GetName() : String {
        match(this) {
            case VALUE(value,bool)  => value.toString()
            case BUNDLER(ms,ns)     => "bundler ${ms} to ${ns}"
            case JOIN(width)        => "join ${width}"
            case GATE(spec)         => spec.GetName() 
            case BLACKBOX(spec)     => spec.GetName()
            case DELAY(dur, width)  => "delay ${dur} width ${width}"
            case IDENTITY           => "id"
            case INLINK(link)       => link.toString()
            case OUTLINK(link)      => link.toString()
        }
    }
}