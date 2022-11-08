/**
 * components/decimal.cj
 *
 * Definition of `Decimal` interface, for defining arrays of values
 * corresponding to decimal numbers
 *
 * @author George Kaye
 * @since 0.3
 */

package components

public interface Decimal<V>
    where V <: ValueSymbol, V <: Equatable<V>
{
    static func UnsignedDecToValues(x : Int64, width : Int64) : Signal<V>
    static func SignedDecToValues(x : Int64, width : Int64) : Signal<V>
    static func DecToValues(x  : Int64, width : Int64, signed : Bool) : Signal<V>
}
public interface DecimalBuilder<V, G>
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    // Signals
    func MakeSignalFromInt(x : Int64, width : Int64, signed : Bool) : InterfacedHypergraph<V, G>
    func MakeSignedSignalFromInt(x : Int64, width : Int64) : InterfacedHypergraph<V, G>
    func MakeUnsignedSignalFromInt(x : Int64, width : Int64) : InterfacedHypergraph<V, G>
    func UseSignalFromInt(x : Int64, width : Int64, signed : Bool) : Wire<V, G>
    func UseSignedSignalFromInt(x : Int64, width : Int64) : Wire<V, G>
    func UseUnsignedSignalFromInt(x : Int64, width : Int64) : Wire<V, G>
    func Zero(width : Int64) : Wire<V, G> {
        this.UseUnsignedSignalFromInt(0, width)
    }
    func Zero() : Wire<V, G> {
        this.Zero(1)
    }
    // Waveforms
    func MakeSignedOpenWaveformFromInt(xs : Array<Int64>, width : Int64) : InterfacedHypergraph<V, G>
    func MakeSignedClosedWaveformFromInt(xs : Array<Int64>, width : Int64) : InterfacedHypergraph<V, G>
    func MakeSignedInfiniteWaveformFromInt(xs : Array<Int64>, width : Int64) : InterfacedHypergraph<V, G>
    func MakeUnsignedOpenWaveformFromInt(xs : Array<Int64>, width : Int64) : InterfacedHypergraph<V, G>
    func MakeUnsignedClosedWaveformFromInt(xs : Array<Int64>, width : Int64) : InterfacedHypergraph<V, G>
    func MakeUnsignedInfiniteWaveformFromInt(xs : Array<Int64>, width : Int64) : InterfacedHypergraph<V, G>
    func UseSignedOpenWaveformFromInt(xs : Array<Int64>, width : Int64, input : Wire<V, G>) : Wire<V, G>
    func UseSignedClosedWaveformFromInt(xs : Array<Int64>, width : Int64) : Wire<V, G>
    func UseSignedInfiniteWaveformFromInt(xs : Array<Int64>, width : Int64) : Wire<V, G>
    func UseUnsignedOpenWaveformFromInt(xs : Array<Int64>, width : Int64, input : Wire<V, G>) : Wire<V, G>
    func UseUnsignedClosedWaveformFromInt(xs : Array<Int64>, width : Int64) : Wire<V, G>
    func UseUnsignedInfiniteWaveformFromInt(xs : Array<Int64>, width : Int64) : Wire<V, G>
    func ConstantZero(width : Int64) : Wire<V, G> {
        this.UseUnsignedInfiniteWaveformFromInt([0], width)
    }
    func ConstantZero() : Wire<V, G> {
        this.ConstantZero(1)
    }
    // Simple register
    func UseSimpleRegister(initial : Int64, width : Int64, signed : Bool, input : Wire<V, G>) : Wire<V, G>
    func RegisterGuardedFeedback(initial : Int64, width : Int64, signed : Bool, input : Wire<V, G>, incoming : Wire<V, G>) : Unit
}
extend Signature<V, G> <: DecimalBuilder<V, G> where V <: Decimal<V> {
    public func MakeSignalFromInt(x : Int64, width : Int64, signed : Bool) : InterfacedHypergraph<V, G> {
        let signal = V.DecToValues(x, width, signed)
        this.MakeSignal(signal)
    }
    public func MakeSignedSignalFromInt(
        x : Int64,
        width : Int64
    ) : InterfacedHypergraph<V, G> {
        this.MakeSignalFromInt(x, width, true)
    }
    public func MakeUnsignedSignalFromInt(
        x : Int64,
        width : Int64
    ) : InterfacedHypergraph<V, G> {
        this.MakeSignalFromInt(x, width, false)
    }
    public func UseSignalFromInt(x : Int64, width : Int64, signed : Bool) : Wire<V, G> {
        let signal = V.DecToValues(x, width, signed)
        this.UseSignal(signal)
    }
    public func UseSignedSignalFromInt(x : Int64, width: Int64) : Wire<V, G> {
        this.UseSignalFromInt(x, width, true)
    }
    public func UseUnsignedSignalFromInt(x : Int64, width: Int64) : Wire<V, G> {
        this.UseSignalFromInt(x, width, false)
    }
    func MakeWaveformFromInt(
        xs : Array<Int64>,
        width : Int64,
        signed : Bool,
        waveformType : WaveformType
    ) : InterfacedHypergraph<V, G> {
        let signals = map({ v : Int64 => V.DecToValues(v, width, signed)}, xs)
        match(waveformType){
            case FINITE_CLOSED => this.MakeClosedWaveform(signals)
            case FINITE_OPEN   => this.MakeOpenWaveform(signals)
            case INFINITE      => this.MakeInfiniteWaveform(signals)
        }
    }
    public func MakeSignedOpenWaveformFromInt(xs : Array<Int64>, width : Int64) : InterfacedHypergraph<V, G> {
        this.MakeWaveformFromInt(xs, width, true, FINITE_OPEN)
    }
    public func MakeSignedClosedWaveformFromInt(xs : Array<Int64>, width : Int64) : InterfacedHypergraph<V, G> {
        this.MakeWaveformFromInt(xs, width, true, FINITE_CLOSED)
    }
    public func MakeSignedInfiniteWaveformFromInt(xs : Array<Int64>, width : Int64) : InterfacedHypergraph<V, G> {
        this.MakeWaveformFromInt(xs, width, true, INFINITE)
    }
    public func MakeUnsignedOpenWaveformFromInt(xs : Array<Int64>, width : Int64) : InterfacedHypergraph<V, G> {
        this.MakeWaveformFromInt(xs, width, false, FINITE_OPEN)
    }
    public func MakeUnsignedClosedWaveformFromInt(xs : Array<Int64>, width : Int64) : InterfacedHypergraph<V, G> {
        this.MakeWaveformFromInt(xs, width, false, FINITE_CLOSED)
    }
    public func MakeUnsignedInfiniteWaveformFromInt(xs : Array<Int64>, width : Int64) : InterfacedHypergraph<V, G> {
        this.MakeWaveformFromInt(xs, width, false, INFINITE)
    }
    func UseOpenWaveformFromInt(xs : Array<Int64>, width : Int64, signed : Bool, input : Wire<V, G>) : Wire<V, G> {
        let signals = map({ v : Int64 => V.DecToValues(v, width, signed)}, xs)
        this.UseOpenWaveform(signals, input)
    }
    func UseClosedWaveformFromInt(xs : Array<Int64>, width : Int64, signed : Bool) : Wire<V, G> {
        let signals = map({ v : Int64 => V.DecToValues(v, width, signed)}, xs)
        this.UseClosedWaveform(signals)
    }
    func UseInfiniteWaveformFromInt(xs : Array<Int64>, width : Int64, signed : Bool) : Wire<V, G> {
        let signals = map({ v : Int64 => V.DecToValues(v, width, signed)}, xs)
        this.UseInfiniteWaveform(signals)
    }
    public func UseSignedOpenWaveformFromInt(xs : Array<Int64>, width : Int64, input : Wire<V, G>) : Wire<V, G> {
        this.UseOpenWaveformFromInt(xs, width, true, input)
    }
    public func UseSignedClosedWaveformFromInt(xs : Array<Int64>, width : Int64) : Wire<V, G> {
        this.UseClosedWaveformFromInt(xs, width, true)
    }
    public func UseSignedInfiniteWaveformFromInt(xs : Array<Int64>, width : Int64) : Wire<V, G> {
        this.UseInfiniteWaveformFromInt(xs, width, true)
    }
    public func UseUnsignedOpenWaveformFromInt(xs : Array<Int64>, width : Int64, input : Wire<V, G>) : Wire<V, G> {
        this.UseOpenWaveformFromInt(xs, width, false, input)
    }
    public func UseUnsignedClosedWaveformFromInt(xs : Array<Int64>, width : Int64) : Wire<V, G> {
        this.UseClosedWaveformFromInt(xs, width, false)
    }
    public func UseUnsignedInfiniteWaveformFromInt(xs : Array<Int64>, width : Int64) : Wire<V, G> {
        this.UseInfiniteWaveformFromInt(xs, width, false)
    }
    // Register
    public func UseSimpleRegister(
        initial : Int64,
        width : Int64,
        signed : Bool,
        input : Wire<V, G>
    ) : Wire<V, G> {
        let signal = V.DecToValues(initial, width, signed)
        this.UseSimpleRegister(signal, input)
    }
    public func RegisterGuardedFeedback(
        initial : Int64,
        width : Int64,
        signed : Bool,
        input : Wire<V, G>,
        incoming : Wire<V, G>
    ) : Unit {
        let signal = V.DecToValues(initial, width, signed)
        this.RegisterGuardedFeedback(signal, input, incoming)
    }
}