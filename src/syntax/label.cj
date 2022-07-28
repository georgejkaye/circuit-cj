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
    | VALUE(Array<Value>, Bool)           // A value 0 -> n, which could be signed or unsigned
    | BUNDLER(Array<Int64>, Array<Int64>) // A bundler changes how wires are bundled
    | JOIN(Int64)                         // Join two wires together
    | PRIMITIVE(Primitive)                // The simplest building blocks of circuits
    | COMPOSITE(Composite)                // A composite of primitives
    | BLACKBOX(BlackBox)                  // A black box with arbitrary name and codomain
    | DELAY(Int64, Int64)                 // A delay parameterised by a duration and a width
}
extend Label <: Specifiable {
    public func GetInputPorts() : Array<Port> {
        match(this) {
            case VALUE(values, signed)  => []
            case BUNDLER(ms, ns)        => map({ m : Int64 => Port(m) }, ms)
            case JOIN(w)            => [Port(w), Port(w)]
            case PRIMITIVE(prim)        => prim.GetInputPorts()
            case COMPOSITE(comp)        => comp.GetInputPorts()
            case BLACKBOX(bb)           => bb.GetInputPorts()
            case DELAY(d, w)            => [Port(w)] 
            
        }
    }
    public func GetNoInputs() : Int64 {
        this.GetInputPorts().size()
    }
    public func GetOutputPorts() : Array<Port> {
        match(this) {
            case VALUE(values, signed)  => [Port(values.size())]
            case BUNDLER(ms,ns)         => map({ n : Int64 => Port(n) }, ns)
            case JOIN(w)                => [Port(w)]
            case PRIMITIVE(prim)        => prim.GetOutputPorts()
            case COMPOSITE(comp)        => comp.GetOutputPorts()
            case BLACKBOX(bb)           => bb.GetOutputPorts()
            case DELAY(d, w)            => [Port(w)]
        }
    }
    public func GetNoOutputs() : Int64 {
        this.GetOutputPorts().size()
    }
    public func GetName() : String {
        match(this) {
            case VALUE(value, signed)   => value.toString()
            case BUNDLER(ms, ns)        => 
                let arrow = if (ms.size() < ns.size()) { "◁" } else { "▷" }
                "${ms.size()}${arrow}${ns.size()}"
            case JOIN(w)                => "∇_${w}"
            case PRIMITIVE(prim)        => prim.GetName()
            case COMPOSITE(comp)        => comp.GetName()
            case BLACKBOX(bb)           => bb.GetName()
            case DELAY(d, w)            => "delay_${d}_{w}"
        }
    }
    public func toString() : String {
        this.GetName()
    }
}