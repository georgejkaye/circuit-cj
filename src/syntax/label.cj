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
public enum Label<V, G> where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G> {
    | VALUE(V)                            // A basic value 0 -> 1
    | SIGNAL(Signal<V>)                   // A collection of values 0 -> n
    | WAVEFORM(Waveform<V>, WaveformType) // A sequence of signals over time, which can be closed or infinite
    | BUNDLER(Array<Int64>, Array<Int64>) // A bundler changes how wires are bundled
    | JOIN(Int64)                         // Join two wires together
    | PRIMITIVE(G)                        // The simplest building blocks of circuits
    | COMPOSITE(Specification<V>)         // A composite of primitives
    | BLACKBOX(Specification<V>)          // A black box with arbitrary name and codomain
    | DELAY(Int64)                        // A delay parameterised by a width
}
extend Label<V, G> <: HasName & Specifiable<V> & ToString & Equatable<Label<V, G>> {
    public func GetInputPorts() : Array<Port<V>> {
        match(this) {
            case VALUE(_)                       => []
            case SIGNAL(spec)                   => []
            case WAVEFORM(wf, wfType) => match(wfType) {
                case FINITE_OPEN => wf.GetInputPorts()
                case _ => Array<Port<V>>()
            }
            case BUNDLER(ms, _)                 => map({ i : Int64 => Port(i)}, ms)
            case JOIN(w)                        => [Port(w), Port(w)]
            case PRIMITIVE(prim)                => prim.GetInputPorts()
            case COMPOSITE(spec)                => spec.GetInputPorts()
            case BLACKBOX(spec)                 => spec.GetInputPorts()
            case DELAY(w)                       => [Port(w)]
        }
    }
    public func GetArity() : Int64 {
        this.GetInputPorts().size
    }
    public func GetOutputPorts() : Array<Port<V>> {
        match(this) {
            case VALUE(_)               => [Port(1)]
            case SIGNAL(spec)           => spec.GetOutputPorts()
            case WAVEFORM(wf, wfType)   => wf.GetOutputPorts()
            case BUNDLER(ms, ns)        => map({ i : Int64 => Port(i)}, ns)
            case JOIN(w)                => [Port(w)]
            case PRIMITIVE(prim)        => prim.GetOutputPorts()
            case COMPOSITE(spec)        => spec.GetOutputPorts()
            case BLACKBOX(spec)         => spec.GetOutputPorts()
            case DELAY(w)               => [Port(w)]
        }
    }
    public func GetCoarity() : Int64 {
        this.GetOutputPorts().size
    }
    public func GetName() : String {
        match(this) {
            case VALUE(v)               => "${v}"
            case SIGNAL(spec)           => spec.GetName()
            case WAVEFORM(wf, wfType)   => match(wfType) {
                case FINITE_OPEN   => "${wf} ::"
                case FINITE_CLOSED => "${wf}"
                case INFINITE      => "(${wf})\u{03C9}"
            }
            case BUNDLER(ms, ns)        => if (ms.size < ns.size) { "\u{25C1}" } else { "\u{25B7}" }
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
    public operator func==(rhs : Label<V, G>) : Bool {
        match(this) {
            case VALUE(v) => match(rhs) {
                case VALUE(w) => v == w
                case _ => false
            }
            case SIGNAL(s) => match(rhs) {
                case SIGNAL(t) => s == t
                case _ => false
            }
            case WAVEFORM(wf1, wfType1) => match(rhs) {
                case WAVEFORM(wf2, wfType2) => wf1 == wf2 && wfType1 == wfType2
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
    public operator func !=(rhs : Label<V, G>) : Bool {
        !(this == rhs)
    }
    public func IsValue() : Bool {
        match(this) {
            case VALUE(_) => true
            case SIGNAL(_) => true
            case _ => false
        }
    }
    public func IsAllValue(v : V) : Bool {
        match(this) {
            case VALUE(w) => v == w
            case SIGNAL(spec) =>
                for(w in spec.values) {
                    if(w != v) {
                        return false
                    }
                }
                true
            case _ => false
        }
    }
    public func GetValue() : V {
        match(this) {
            case VALUE(v) => v
            case _ => throw IncompatibleVariantException(this, "VALUE")
        }
    }
    public func GetValueArray() : Array<V> {
        match(this) {
            case VALUE(v) => [v]
            case SIGNAL(vs) => vs.values
            case _ => throw IncompatibleVariantException(this, "VALUE/SIGNAL")
        }
    }
    public func IsPrimitive() : Bool {
        match(this) {
            case PRIMITIVE(_) => true
            case _ => false
        }
    }
    public func GetPrimitive() : G {
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
    public func IsJoin() : Bool {
        match(this) {
            case JOIN(_) => true
            case _ => false
        }
    }
    public func IsComposite() : Bool {
        match(this) {
            case COMPOSITE(_) => true
            case _ => false
        }
    }
    public func IsBundler() : Bool {
        match(this) {
            case BUNDLER(_, _) => true
            case _ => false
        }
    }
    public func GetBundlerSpec() : (Array<Int64>, Array<Int64>) {
        match(this) {
            case BUNDLER(ms, ns) => (ms, ns)
            case _ => throw IncompatibleVariantException(this, "BUNDLER")
        }
    }
}

public func GetSignalLabel<V, G>(v : V, w : Int64) : Label<V, G>
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    if(w == 1) {
        VALUE(v)
    } else {
        let signal = Signal(v, w)
        SIGNAL(signal)
    }
}

public func GetSignalLabel<V, G>(values : Array<V>) : Label<V, G>
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    if(values.size == 1) {
        VALUE(values[0])
    } else {
        SIGNAL(Signal(values))
    }
}