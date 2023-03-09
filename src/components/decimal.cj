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
    where V <: ValueSymbol<V> & Equatable<V> & LessOrEqual<V>
{
    static func UnsignedDecToSignal(x : Int64, width : Int64) : Signal<V>
    static func SignedDecToSignal(x : Int64, width : Int64) : Signal<V>
    static func DecToSignal(x  : Int64, width : Int64, signed : Bool) : Signal<V>
}
public func MakeSignalFromInt<V, G>(
    x : Int64, width : Int64, signed!: Bool
) : InterfacedHypergraph<V, G>
    where
        V <: ValueSymbol<V> & Equatable<V> & LessOrEqual<V> & Decimal<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
{
    let signal = V.DecToSignal(x, width, signed)
    MakeSignal(signal)
}
func MakeDecimalSignalArray<V>(
    vs : Array<Int64>, width: Int64, signed: Bool
) : Array<Signal<V>>
    where
        V <: ValueSymbol<V> & Equatable<V> & LessOrEqual<V> & Decimal<V>
{
    map({ v : Int64 => V.DecToSignal(v, width, signed)}, vs)
}
public func MakeOpenWaveformFromInt<V, G>(
    xs : Array<Int64>, width!: Int64, signed!: Bool
) : InterfacedHypergraph<V, G>
    where
        V <: ValueSymbol<V> & Equatable<V> & LessOrEqual<V> & Decimal<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
{
    let signals = MakeDecimalSignalArray<V>(xs, width, signed)
    MakeOpenWaveform(signals)
}
public func MakeClosedWaveformFromInt<V, G>(
    xs : Array<Int64>, width!: Int64, signed!: Bool
) : InterfacedHypergraph<V, G>
    where
        V <: ValueSymbol<V> & Equatable<V> & LessOrEqual<V> & Decimal<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
{
    let signals = MakeDecimalSignalArray<V>(xs, width, signed)
    MakeClosedWaveform(signals)
}
public func MakeInfiniteWaveformFromInt<V, G>(
    xs : Array<Int64>, width!: Int64, signed!: Bool
) : InterfacedHypergraph<V, G>
    where
        V <: ValueSymbol<V> & Equatable<V> & LessOrEqual<V> & Decimal<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
{
    let signals = MakeDecimalSignalArray<V>(xs, width, signed)
    MakeInfiniteWaveform(signals)
}
public func UseSignalFromInt<V, G>(
    x : Int64, width!: Int64, signed!: Bool
) : Wire<V, G>
    where
        V <: ValueSymbol<V> & Equatable<V> & LessOrEqual<V> & Decimal<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
{
    let signal = V.DecToSignal(x, width, signed)
    UseSignal(signal)
}
public func UseInstantZero<V, G>(width!: Int64) : Wire<V, G>
    where
        V <: ValueSymbol<V> & Equatable<V> & LessOrEqual<V> & Decimal<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
{
    UseSignalFromInt(0, width: width, signed: false)
}
public func UseConstantZero<V, G>(width!: Int64) : Wire<V, G>
    where
        V <: ValueSymbol<V> & Equatable<V> & LessOrEqual<V> & Decimal<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
{
    UseInfiniteWaveformFromInt([0], width: width, signed: false)
}
func UseOpenWaveformFromInt<V, G>(
    xs : Array<Int64>,  input : Wire<V, G>, width!: Int64, signed!: Bool
) : Wire<V, G>
    where
        V <: ValueSymbol<V> & Equatable<V> & LessOrEqual<V> & Decimal<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
{
    let signals = MakeDecimalSignalArray<V>(xs, width, signed)
    UseOpenWaveform(signals, input)
}
func UseClosedWaveformFromInt<V, G>(
    xs : Array<Int64>, width!: Int64, signed!: Bool
) : Wire<V, G>
    where
        V <: ValueSymbol<V> & Equatable<V> & LessOrEqual<V> & Decimal<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
{
    let signals = MakeDecimalSignalArray<V>(xs, width, signed)
    UseClosedWaveform(signals)
}
func UseInfiniteWaveformFromInt<V, G>(
    xs : Array<Int64>, width!: Int64, signed!: Bool
) : Wire<V, G>
    where
        V <: ValueSymbol<V> & Equatable<V> & LessOrEqual<V> & Decimal<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
{
    let signals = MakeDecimalSignalArray<V>(xs, width, signed)
    UseInfiniteWaveform(signals)
}
public interface DecimalSignalUser<V, G>
    where
        V <: ValueSymbol<V> & Equatable<V> & LessOrEqual<V> & Decimal<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
{
    func UseSignalFromInt(
        x : Int64, width!: Int64, signed!: Bool
    ) : Wire<V, G> {
        UseSignalFromInt<V, G>(x, width: width, signed: signed)
    }
    func UseInstantZero(width!: Int64) : Wire<V, G> {
        UseInstantZero<V, G>(width: width)
    }
    func UseConstantZero(width!: Int64) : Wire<V, G> {
        UseConstantZero<V, G>(width: width)
    }
    func UseOpenWaveformFromInt(
        xs : Array<Int64>, input: Wire<V, G>, width!: Int64, signed!: Bool
    ) : Wire<V, G> {
        UseOpenWaveformFromInt<V, G>(xs, input, width: width, signed: signed)
    }
    func UseClosedWaveformFromInt(
        xs : Array<Int64>, width!: Int64, signed!: Bool
    ) : Wire<V, G> {
        UseClosedWaveformFromInt<V, G>(xs, width: width, signed: signed)
    }
    func UseInfiniteWaveformFromInt(
        xs : Array<Int64>, width!: Int64, signed!: Bool
    ) : Wire<V, G> {
        UseInfiniteWaveformFromInt<V, G>(xs, width: width, signed: signed)
    }
}
extend Signature<V, G> <: DecimalSignalUser<V, G>
    where
        V <: ValueSymbol<V> & Equatable<V> & LessOrEqual<V> & Decimal<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
{}

// Register
public func UseSimpleRegister<V, G>(
    initial : Int64,
    width : Int64,
    signed : Bool,
    input : Wire<V, G>
) : Wire<V, G>
    where
        V <: ValueSymbol<V> & Equatable<V> & LessOrEqual<V> & Decimal<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
{
    let signal = V.DecToSignal(initial, width, signed)
    UseSimpleRegister(signal, input)
}
public func RegisterGuardedFeedback<V, G>(
    initial : Int64,
    width : Int64,
    signed : Bool,
    input : Wire<V, G>,
    incoming : Wire<V, G>
) : Unit
    where
        V <: ValueSymbol<V> & Equatable<V> & LessOrEqual<V> & Decimal<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
{
    let signal = V.DecToSignal(initial, width, signed)
    RegisterGuardedFeedback(signal, input, incoming)
}