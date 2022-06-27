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
    init (name : String, inputs : Int64) {
        this.spec = Specification(name, Array<Int64>(inputs, { i : Int64 => 1 }), [1])
    }
    init (name : String, inputs : Array<Int64>, width : Int64) {
        this.spec = Specification(name, inputs, [width])
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


/**
 * Enum for the different types of generators
 */
public enum Label { 
    | VALUE(Array<Value>, Bool)           // A value 0 -> n, which could be signed or unsigned
    | BUNDLER(Array<Int64>, Array<Int64>) // A bundler changes how wires are bundled
    | JOIN(Int64)                         // Join two wires together
    | PRIMITIVE(GateSpecification)        // The simplest building blocks of circuits
    | COMPOSITE(Specification)            // A composite of primitives
    | BLACKBOX(Specification)             // A black box with arbitrary name and codomain
    | DELAY(Int64, Int64)                 // A delay parameterised by a duration and a width
}
extend Label <: ToString & Nameable {
    public func toString() : String {
        match(this){
            case VALUE(values, signed)  => "value (${values}), ${if(!signed){"un"}}signed"
            case BUNDLER(ms,ns)         => "bundler ${ms} to ${ms}"
            case JOIN(width)            => "join ${width}"
            case PRIMITIVE(spec)        => "primitive (${spec.GetName()})"
            case COMPOSITE(spec)        => "composite (${spec.GetName()})"
            case BLACKBOX(spec)         => "black box (${spec.GetName()})"
            case DELAY(dur, width)      => "delay (${dur}) width ${width}"
        }
    }
    public func GetInputType() : Array<Int64> {
        match(this) {
            case VALUE(values,signed)   => []
            case BUNDLER(ms,ns)         => ms
            case JOIN(width)            => [width,width]
            case PRIMITIVE(spec)        => spec.GetInputType() 
            case COMPOSITE(spec)        => spec.GetInputType() 
            case BLACKBOX(spec)         => spec.GetInputType()
            case DELAY(dur, width)      => [width] 
        }
    }
    public func GetOutputType() : Array<Int64> {
        match(this) {
            case VALUE(values,signed)   => [values.size()]
            case BUNDLER(ms,ns)         => ns
            case JOIN(width)            => [width]
            case PRIMITIVE(spec)        => spec.GetOutputType() 
            case COMPOSITE(spec)        => spec.GetOutputType() 
            case BLACKBOX(spec)         => spec.GetOutputType()
            case DELAY(dur, width)      => [width]
        }
    }
    public func GetName() : String {
        match(this) {
            case VALUE(value,bool)  => value.toString()
            case BUNDLER(ms,ns)     => "bundler ${ms} to ${ns}"
            case JOIN(width)        => "join ${width}"
            case PRIMITIVE(spec)    => spec.GetName()
            case COMPOSITE(spec)    => spec.GetName()
            case BLACKBOX(spec)     => spec.GetName()
            case DELAY(dur, width)  => "delay ${dur} width ${width}"
        }
    }
}