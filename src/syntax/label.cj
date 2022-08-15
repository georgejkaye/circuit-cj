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
    | VALUES(ValueSpec)                   // A collection of values 0 -> n, which could be signed or unsigned
    | BUNDLER(Array<Int64>, Array<Int64>) // A bundler changes how wires are bundled
    | JOIN(Int64)                         // Join two wires together
    | PRIMITIVE(Primitive)                // The simplest building blocks of circuits
    | COMPOSITE(Specification)            // A composite of primitives
    | BLACKBOX(Specification)             // A black box with arbitrary name and codomain
    | DELAY(Int64, Int64)                 // A delay parameterised by a duration and a width
}
extend Label <: HasName & Specifiable & ToString {
    public func GetInputPorts() : Array<Port> {
        match(this) {
            case VALUE(_)               => []
            case VALUES(spec)           => []
            case BUNDLER(ms, _)         => map({ i : Int64 => Port(i)}, ms)
            case JOIN(w)                => [Port(w), Port(w)]
            case PRIMITIVE(prim)        => prim.GetInputPorts()
            case COMPOSITE(spec)        => spec.GetInputPorts()
            case BLACKBOX(spec)         => spec.GetInputPorts()
            case DELAY(d, w)            => [Port(w)]

        }
    }
    public func GetNoInputs() : Int64 {
        this.GetInputPorts().size
    }
    public func GetOutputPorts() : Array<Port> {
        match(this) {
            case VALUE(_)               => [Port(1)]
            case VALUES(spec)           => spec.GetOutputPorts()
            case BUNDLER(ms,ns)         => map({ i : Int64 => Port(i)}, ns)
            case JOIN(w)                => [Port(w)]
            case PRIMITIVE(prim)        => prim.GetOutputPorts()
            case COMPOSITE(spec)        => spec.GetOutputPorts()
            case BLACKBOX(spec)         => spec.GetOutputPorts()
            case DELAY(d, w)            => [Port(w)]
        }
    }
    public func GetNoOutputs() : Int64 {
        this.GetOutputPorts().size
    }
    public func GetName() : String {
        match(this) {
            case VALUE(v)               => v.toString()
            case VALUES(spec)           => spec.GetName()
            case BUNDLER(ms, ns)        =>
                let arrow = if (ms.size < ns.size) { "\u{25C1}" } else { "\u{25B7}" }
                "${ms.size}${arrow}${ns.size}"
            case JOIN(w)                => "\u{2207}_${w}"
            case PRIMITIVE(prim)        => prim.GetName()
            case COMPOSITE(spec)        => spec.GetName()
            case BLACKBOX(spec)         => spec.GetName()
            case DELAY(d, w)            => "delay_${d}_{w}"
        }
    }
    public func toString() : String {
        this.GetName()
    }
}