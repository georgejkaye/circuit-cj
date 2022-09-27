/**
 * syntax/label.cj
 *
 * This file contains the definition of generators
 * (in the free categorical sense)
 *
 * @author George Kaye
 * @since 0.2
 */

package syntax

import prelude.*

from std import collection.ArrayList


/**
 * Enum for the different types of generators
 */
public enum Label {
    | VALUE(Value)                        // A basic value 0 -> 1
    | SIGNAL(Signal)                      // A collection of values 0 -> n, which could be signed or unsigned
    | BUNDLER(Array<Int64>, Array<Int64>) // A bundler changes how wires are bundled
    | JOIN(Int64)                         // Join two wires together
    | PRIMITIVE(Primitive)                // The simplest building blocks of circuits
    | COMPOSITE(Specification)            // A composite of primitives
    | BLACKBOX(Specification)             // A black box with arbitrary name and codomain
    | DELAY(Int64)                        // A delay parameterised by a width
}
extend Label <: HasName & Specifiable & ToString & Equatable<Label> {
    public func GetInputPorts() : Array<Port> {
        match(this) {
            case VALUE(_)               => []
            case SIGNAL(spec)           => []
            case BUNDLER(ms, _)         => map({ i : Int64 => Port(i)}, ms)
            case JOIN(w)                => [Port(w), Port(w)]
            case PRIMITIVE(prim)        => prim.GetInputPorts()
            case COMPOSITE(spec)        => spec.GetInputPorts()
            case BLACKBOX(spec)         => spec.GetInputPorts()
            case DELAY(w)               => [Port(w)]

        }
    }
    public func GetNoInputs() : Int64 {
        this.GetInputPorts().size()
    }
    public func GetOutputPorts() : Array<Port> {
        match(this) {
            case VALUE(_)               => [Port(1)]
            case SIGNAL(spec)           => spec.GetOutputPorts()
            case BUNDLER(ms,ns)         => map({ i : Int64 => Port(i)}, ns)
            case JOIN(w)                => [Port(w)]
            case PRIMITIVE(prim)        => prim.GetOutputPorts()
            case COMPOSITE(spec)        => spec.GetOutputPorts()
            case BLACKBOX(spec)         => spec.GetOutputPorts()
            case DELAY(w)               => [Port(w)]
        }
    }
    public func GetNoOutputs() : Int64 {
        this.GetOutputPorts().size()
    }
    public func GetName() : String {
        match(this) {
            case VALUE(v)               => "${v}"
            case SIGNAL(spec)           => spec.GetName()
            case BUNDLER(ms, ns)        => if (ms.size() < ns.size()) { "\u{25C1}" } else { "\u{25B7}" }
            case JOIN(w)                => "\u{2207}_${w}"
            case PRIMITIVE(prim)        => prim.GetName()
            case COMPOSITE(spec)        => spec.GetName()
            case BLACKBOX(spec)         => spec.GetName()
            case DELAY(w)               => "delay_${w}"
        }
    }
    public func toString() : String {
        this.GetName()
    }
    public operator func==(rhs : Label) : Bool {
        match(this) {
            case VALUE(v) => match(rhs) {
                case VALUE(w) => v == w
                case _ => false
            }
            case SIGNAL(s) => match(rhs) {
                case SIGNAL(t) => s == t
                case _ => false
            }
            case BUNDLER(ms, ns) => match(rhs) {
                case BUNDLER(ms2, ns2) => ms == ms2 && ns == ns2
                case _ => false
            }
            case JOIN(w) => match(rhs) {
                case JOIN(w2) => w == w2
                case _ => false
            }
            case PRIMITIVE(p1) => match(rhs) {
                case PRIMITIVE(p2) => p1 == p2
                case _ => false
            }
            case COMPOSITE(s1) => match(rhs) {
                case COMPOSITE(s2) => s1 == s2
                case _ => false
            }
            case BLACKBOX(s1) => match(rhs) {
                case BLACKBOX(s2) => s1 == s2
                case _ => false
            }
            case DELAY(w1) => match(rhs) {
                case DELAY(w2) => w1 == w2
                case _ => false
            }
        }
    }
    public operator func !=(rhs : Label) : Bool {
        !(this == rhs)
    }
    public func IsValue() : Bool {
        match(this) {
            case VALUE(_) => true
            case SIGNAL(_) => true
            case _ => false
        }
    }
    public func GetValue() : Value {
        match(this) {
            case VALUE(v) => v
            case _ => throw IncompatibleVariantException(this, "VALUE")
        }
    }
    public func IsPrimitive() : Bool {
        match(this) {
            case PRIMITIVE(_) => true
            case _ => false
        }
    }
    public func GetPrimitive() : Primitive {
        match(this) {
            case PRIMITIVE(prim) => prim
            case _ => throw IncompatibleVariantException(this, "PRIMITIVE")
        }
    }
    public func IsDelay() : Bool {
        match(this) {
            case DELAY(_) => true
            case _ => false
        }
    }
}

public func GetSignalLabel(v : Value, w : Int64){
    if(w == 1) {
        VALUE(v)
    } else {
        let signal = Signal(v, w)
        SIGNAL(signal)
    }
}