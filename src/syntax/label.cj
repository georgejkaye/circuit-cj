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
import utils.*
from std import collection.ArrayList
/**
 * Enum for the different types of generators
 */
public enum Label<V, G>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    // A basic value 0 -> 1
    | VALUE(V)
    // A collection of values 0 -> n
    | SIGNAL(Signal<V>)
    // A partially specified input
    | PARTIAL(VariableSignal<V>)
    // A join of a signal and a delay
    | REGISTER(CycleInput<V>)
    // A sequence of signals over time
    | OPEN_WAVEFORM(Waveform<V>)
    // A sequence of signals over time, capped with a disconnect
    | CLOSED_WAVEFORM(Waveform<V>)
    // A sequence of signals over time that repeats periodically
    | INFINITE_WAVEFORM(Waveform<V>)
    // A bundler changes how wires are bundled
    | BUNDLER(Array<Int64>, Array<Int64>)
    // Join two wires together
    | JOIN(Int64)
    // The simplest building blocks of circuits
    | PRIMITIVE(G)
    // An primitive that has been enhanced (e.g. a bitwise variant)
    | ENHANCED_PRIMITIVE(EnhancedPrimitive<V, G>)
    // A composite of primitives
    | COMPOSITE(Specification)
     // A black box with arbitrary name, arity and coarity
    | BLACKBOX(Blackbox<V, G>)
    // A delay parameterised by a width
    | DELAY(Int64)
}
/**
 * Unicode character for omega, used to denote infinite waveforms
 */
let omega = "\u{03C9}"
let bundleExpand = "\u{25C1}"
let bundleCombine = "\u{25B7}"
extend Label<V, G>
    <: HasName & Specifiable & ToString & Equatable<Label<V, G>>
{
    public func GetInputPorts() : Array<Port> {
        match(this) {
            case VALUE(_) =>
                []
            case SIGNAL(_) =>
                []
            case PARTIAL(_) =>
                []
            case REGISTER(signal) =>
                [Port(signal.GetWidth())]
            case OPEN_WAVEFORM(wf) =>
                [Port(wf.GetSignalAtTick(0).GetWidth())]
            case CLOSED_WAVEFORM(wf) =>
                []
            case INFINITE_WAVEFORM(wf) =>
                []
            case BUNDLER(ms, _) =>
                map({ i : Int64 => Port(i)}, ms)
            case JOIN(w) =>
                [Port(w), Port(w)]
            case PRIMITIVE(prim) =>
                prim.GetInputPorts()
            case ENHANCED_PRIMITIVE(eprim) =>
                eprim.GetInputPorts()
            case COMPOSITE(spec) =>
                spec.GetInputPorts()
            case BLACKBOX(spec) =>
                spec.GetInputPorts()
            case DELAY(w) =>
                [Port(w)]
        }
    }
    public func GetOutputPorts() : Array<Port> {
        match(this) {
            case VALUE(_) =>
                [Port(1)]
            case SIGNAL(spec) =>
                spec.GetOutputPorts()
            case PARTIAL(ws) =>
                [Port(ws.GetWidth())]
            case REGISTER(signal) =>
                [Port(signal.GetWidth())]
            case OPEN_WAVEFORM(wf) =>
                [Port(wf.GetSignalAtTick(0).GetWidth())]
            case CLOSED_WAVEFORM(wf) =>
                [Port(wf.GetSignalAtTick(0).GetWidth())]
            case INFINITE_WAVEFORM(wf) =>
                [Port(wf.GetSignalAtTick(0).GetWidth())]
            case BUNDLER(ms, ns) =>
                map({ i : Int64 => Port(i)}, ns)
            case JOIN(w) =>
                [Port(w)]
            case PRIMITIVE(prim) =>
                prim.GetOutputPorts()
            case ENHANCED_PRIMITIVE(eprim) =>
                eprim.GetOutputPorts()
            case COMPOSITE(spec) =>
                spec.GetOutputPorts()
            case BLACKBOX(spec) =>
                spec.GetOutputPorts()
            case DELAY(w) => [Port(w)]
        }
    }
    public func GetName() : String {
        match(this) {
            case VALUE(v) =>
                "${v}"
            case SIGNAL(spec) =>
                spec.GetName()
            case PARTIAL(ps) =>
                ps.GetName()
            case REGISTER(signal) =>
                "${signal.GetName()} ::"
            case OPEN_WAVEFORM(wf) =>
                "${wf.GetName()} ::"
            case CLOSED_WAVEFORM(wf) =>
                wf.GetName()
            case INFINITE_WAVEFORM(wf) =>
                "(${wf.GetName()})${omega}"
            case BUNDLER(ms, ns) =>
                if (ms.size < ns.size) { bundleExpand } else { bundleCombine }
            case JOIN(w) =>
                "\u{2207}_${w}"
            case PRIMITIVE(prim) =>
                prim.GetName()
            case ENHANCED_PRIMITIVE(eprim) =>
                eprim.GetName()
            case COMPOSITE(spec) =>
                spec.GetName()
            case BLACKBOX(spec) =>
                spec.GetName()
            case DELAY(w) =>
                "delay_${w}"
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
            case PARTIAL(p) => match(rhs) {
                case PARTIAL(q) => false
                case _ => false
            }
            case REGISTER(s) => match(rhs) {
                case REGISTER(t) => false
                case _ => false
            }
            case OPEN_WAVEFORM(wf1) => match(rhs) {
                case OPEN_WAVEFORM(wf2) => wf1 == wf2
                case _ => false
            }
            case CLOSED_WAVEFORM(wf1) => match(rhs) {
                case CLOSED_WAVEFORM(wf2) => wf1 == wf2
                case _ => false
            }
            case INFINITE_WAVEFORM(wf1) => match(rhs) {
                case INFINITE_WAVEFORM(wf2) => wf1 == wf2
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
            case ENHANCED_PRIMITIVE(ep1) => match(rhs) {
                case ENHANCED_PRIMITIVE(ep2) => ep1 == ep2
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
    /**
     * @return if this a value or a signal label
     */
    public func IsSignal() : Bool {
        match(this) {
            case VALUE(_) => true
            case SIGNAL(_) => true
            case _ => false
        }
    }
    public func IsCycleInput() : Bool {
        match(this) {
            case VALUE(_) => true
            case SIGNAL(_) => true
            case PARTIAL(_) => true
            case _ => false
        }
    }
    public func GetCycleInput() : CycleInput<V> {
        match(this) {
            case VALUE(v) => CycleInput<V>.DEFINITE(Signal(v))
            case SIGNAL(s) => CycleInput<V>.DEFINITE(s)
            case PARTIAL(p) => CycleInput<V>.PARTIAL(p)
            case _ => throw IncompatibleVariantException(this, "CycleInput")
        }
    }

    /**
     * @param v a value symbol
     * @return Whether thie value or signal label only contains this symbol
     */
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
    /**
     * @return the value of this label: throws exception if not a value
     */
    public func GetValue() : V {
        match(this) {
            case VALUE(v) => v
            case _ => throw IncompatibleVariantException(this, "VALUE")
        }
    }
    /**
     * @return the signal of this label: throws exception if not value or signal
     */
    public func GetSignal() : Signal<V> {
        match(this) {
            case VALUE(v) => Signal(v)
            case SIGNAL(spec) => spec
            case REGISTER(ci) => match(ci) {
                case DEFINITE(s) => s
                case PARTIAL(p) =>
                    throw IncompatibleVariantException(
                        this, "VALUE/SIGNAL/REGISTER"
                    )
            }
            case _ =>
                throw IncompatibleVariantException(
                    this, "VALUE/SIGNAL/REGISTER"
                )
        }
    }
    /**
     * @return the signal of this label, or None if there isn't one
     */
    public func GetMaybeSignal() : Option<Signal<V>> {
        match(this) {
            case VALUE(v) => Some(Signal(v))
            case SIGNAL(spec) => Some(spec)
            case REGISTER(ci) => match(ci) {
                case DEFINITE(s) => Some(s)
                case _ => None
            }
            case _ => None
        }
    }
    /**
     * @return the value array of this label:
     *           throws exception if not a value or signal
     */
    public func GetValueArray() : Array<V> {
        match(this) {
            case VALUE(v) => [v]
            case SIGNAL(vs) => vs.values
            case _ => throw IncompatibleVariantException(this, "VALUE/SIGNAL")
        }
    }
    /**
     * @return if this label is a primitive
     */
    public func IsPrimitive() : Bool {
        match(this) {
            case PRIMITIVE(_) => true
            case _ => false
        }
    }
    /**
    * @return the primitive symbol of this label:
        throws exception if not a primitive
     */
    public func GetPrimitive() : G {
        match(this) {
            case PRIMITIVE(prim) => prim
            case _ => throw IncompatibleVariantException(this, "PRIMITIVE")
        }
    }
    /**
     * @return if this label is a delay
     */
    public func IsDelay() : Bool {
        match(this) {
            case DELAY(_) => true
            case _ => false
        }
    }
    /**
     * @return if this label is a join
     */
    public func IsJoin() : Bool {
        match(this) {
            case JOIN(_) => true
            case _ => false
        }
    }
    /**
     * @return if this label is a composite
     */
    public func IsComposite() : Bool {
        match(this) {
            case COMPOSITE(_) => true
            case _ => false
        }
    }
    /**
     * @return if this label is a bundler
     */
    public func IsBundler() : Bool {
        match(this) {
            case BUNDLER(_, _) => true
            case _ => false
        }
    }
    /**
     * @return the bundler spec of this label:
     *   throws exception if not a bundler
     */
    public func GetBundlerSpec() : (Array<Int64>, Array<Int64>) {
        match(this) {
            case BUNDLER(ms, ns) => (ms, ns)
            case _ => throw IncompatibleVariantException(this, "BUNDLER")
        }
    }
    /**
     * @return if this label is a waveform of any type
     */
    public func IsWaveform() : Bool {
        match(this) {
            case OPEN_WAVEFORM(_) => true
            case CLOSED_WAVEFORM(_) => true
            case INFINITE_WAVEFORM(_) => true
            case _ => false
        }
    }
    /**
     * @return the waveform of this label:
     *  throws exception if not a waveform
     */
    public func GetWaveform() : Waveform<V> {
        match(this) {
            case OPEN_WAVEFORM(wf) => wf
            case CLOSED_WAVEFORM(wf) => wf
            case INFINITE_WAVEFORM(wf) => wf
            case _ => throw IncompatibleVariantException(this, "WAVEFORM")
        }
    }
    /**
     * @return the waveform of this label:
     *  throws exception if not a waveform
     */
    public func GetMaybeWaveform() : Option<Waveform<V>> {
        match(this) {
            case OPEN_WAVEFORM(wf) => Some(wf)
            case CLOSED_WAVEFORM(wf) => Some(wf)
            case INFINITE_WAVEFORM(wf) => Some(wf)
            case _ => None
        }
    }
    /**
     * @return if this is a register label
     */
    public func IsRegister() : Bool {
        match(this) {
            case REGISTER(_) => true
            case _ => false
        }
    }
    /**
     * Check if a subgraph should be expanded based on its label.
     *
     * @param expandSignals
                Whether to expand subgraphs for signals and associated
                constructs, which are not normally interesting enough to show
     * @return If this label is expandable, i.e. its contents are interesting
     *          enough to look into.
     */
    public func IsExpandable(expandSignals!: Bool = false) : Bool {
        match(this) {
            case COMPOSITE(_)          => true
            case ENHANCED_PRIMITIVE(_) => true
            case SIGNAL(_)             => expandSignals
            case CLOSED_WAVEFORM(_)    => expandSignals
            case OPEN_WAVEFORM(_)      => expandSignals
            case INFINITE_WAVEFORM(_)  => expandSignals
            case REGISTER(_)           => expandSignals
            case _                     => false
        }
    }
    /**
     * @return if this is an enhanced label
     */
    public func IsEnhanced() : Bool {
        match(this) {
            case ENHANCED_PRIMITIVE(_) => true
            case _ => false
        }
    }
    /**
     * @return if this is a blackbox label
     */
    public func IsBlackBox() : Bool {
        match(this) {
            case BLACKBOX(_) => true
            case _ => false
        }
    }
    public func GetVariant() : String {
        match(this) {
            case VALUE(_) => "VALUE"
            case SIGNAL(spec) => "SIGNAL"
            case PARTIAL(p) => "PARTIAL"
            case REGISTER(signal) => "REGISTER"
            case OPEN_WAVEFORM(wf) => "OPEN_WAVEFORM"
            case CLOSED_WAVEFORM(wf) => "CLOSED_WAVEFORM"
            case INFINITE_WAVEFORM(wf) => "INFINITE_WAVEFORM"
            case BUNDLER(ms, _) => "BUNDLER"
            case JOIN(w) => "JOIN"
            case PRIMITIVE(prim) => "PRIMITIVE"
            case ENHANCED_PRIMITIVE(eprim) => "ENHANCED_PRIMITIVE"
            case COMPOSITE(spec) => "COMPOSITE"
            case BLACKBOX(spec) => "BLACKBOX"
            case DELAY(w) => "DELAY"
        }
    }
}
/**
 * Given a value, get the label for a given number of this value in parallel.
 * If there is only one value, this will be a VALUE label; otherwise it will be
 * a SIGNAL.
 *
 * @param v The value
 * @param w How many values to have in parallel
 * @return The corresponding label for these values
 */
public func GetSignalLabel<V, G>(v : V, w : Int64) : Label<V, G>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    if(w == 1) {
        VALUE(v)
    } else {
        let signal = Signal(v, w)
        SIGNAL(signal)
    }
}
/**
 * Given an array of values, get the corresponding label. If the list has one
 * element, this will be a VALUE label; otherwise it will be a SIGNAL.
 *
 * @param values
 * @return The corresponding label for these values
 */
public func GetSignalLabel<V, G>(signal : Signal<V>) : Label<V, G>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    if(signal.GetWidth() == 1) {
        VALUE(signal.GetBit(0))
    } else {
        SIGNAL(signal)
    }
}