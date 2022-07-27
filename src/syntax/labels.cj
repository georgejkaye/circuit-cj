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

public interface Specifiable <: Nameable {
    func GetInputPorts() : Array<Port>
    func GetOutputPorts() : Array<Port>
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

public record Port <: ToString & Equatable<Port> {
    public Port(
        public let width : Int64,
        public let name! : Option<String> = None
    ){}
    public func toString() : String {
        let nameString = match(name) {
            case None => ""
            case Some(n) => " ${n}"
        }
        "${width}${nameString}"
    }
    public operator func ==(rhs: Port) : Bool {
        this.width == rhs.width && this.name == rhs.name
    }
    public operator func !=(rhs: Port) : Bool {
        !(this == rhs)
    }
}

public interface HasWidth {
    func GetWidth() : Int64
}

extend Port <: HasWidth {
    public func GetWidth() : Int64 {
        this.width
    }
}

extend Int64 <: HasWidth {
    public func GetWidth() : Int64 {
        this
    }
}

/**
 * Interfaces have a name, domain and codomain
 * (Gates are a special case in which codomain is 1)
 */
public record Specification <: ToString & Equatable<Specification> & Specifiable {
    public Specification(
        public let name : String, 
        public let dom : Array<Port>,
        public let cod : Array<Port>
    ) {}
    public func toString() : String {
        "${name} : ${dom} → ${cod}" 
    }
    public operator func ==(rhs: Specification) : Bool {
        this.name == rhs.name && this.dom == rhs.dom && this.cod == rhs.cod
    }
    public operator func !=(rhs: Specification) : Bool { 
        !(this == rhs) 
    }
    public func GetName() : String {
        this.name
    }
    public func GetInputPorts() : Array<Port> {
        this.dom
    }
    public func GetOutputPorts() : Array<Port> {
        this.cod
    }
}

/**
 * Enum for the different types of generators
 */
public enum Label { 
    | VALUE(Array<Value>, Bool)           // A value 0 -> n, which could be signed or unsigned
    | BUNDLER(Array<Int64>, Array<Int64>) // A bundler changes how wires are bundled
    | JOIN(Int64)                         // Join two wires together
    | PRIMITIVE(Specification)            // The simplest building blocks of circuits
    | COMPOSITE(Specification)            // A composite of primitives
    | BLACKBOX(Specification)             // A black box with arbitrary name and codomain
    | DELAY(Int64, Int64)                 // A delay parameterised by a duration and a width
}
extend Label <: ToString & Specifiable {
    public func toString() : String {
        match(this){
            case VALUE(values, signed)  => "value (${values}), ${if(!signed){"un"}}signed"
            case BUNDLER(ms, ns)        => "bundler ${ms} to ${ms}"
            case JOIN(width)            => "join ${width}"
            case PRIMITIVE(spec)        => "${spec.name}"
            case COMPOSITE(spec)        => "${spec.name}"
            case BLACKBOX(spec)         => "${spec.name}"
            case DELAY(dur, width)      => "delay (${dur}) width ${width}"
        }
    }
    public func GetInputPorts() : Array<Port> {
        match(this) {
            case VALUE(values, signed)  => []
            case BUNDLER(ms, ns)        => map({ m : Int64 => Port(m) }, ms)
            case JOIN(width)            => [Port(width), Port(width)]
            case PRIMITIVE(spec)        => spec.dom
            case COMPOSITE(spec)        => spec.dom
            case BLACKBOX(spec)         => spec.dom
            case DELAY(dur, width)      => [Port(width)] 
        }
    }
    public func GetOutputPorts() : Array<Port> {
        match(this) {
            case VALUE(values, signed)  => [Port(values.size())]
            case BUNDLER(ms,ns)         => map({ n : Int64 => Port(n) }, ns)
            case JOIN(width)            => [Port(width)]
            case PRIMITIVE(spec)        => spec.cod 
            case COMPOSITE(spec)        => spec.cod 
            case BLACKBOX(spec)         => spec.cod
            case DELAY(dur, width)      => [Port(width)]
        }
    }
    public func GetName() : String {
        match(this) {
            case VALUE(value, signed)   => value.toString()
            case BUNDLER(ms, ns)        => "bundler ${ms} to ${ns}"
            case JOIN(width)            => "join ${width}"
            case PRIMITIVE(spec)        => spec.name
            case COMPOSITE(spec)        => spec.name
            case BLACKBOX(spec)         => spec.name
            case DELAY(dur, width)      => "delay ${dur} width ${width}"
        }
    }
}