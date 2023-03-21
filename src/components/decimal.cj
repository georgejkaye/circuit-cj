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
/**
 * Interface for value sets that can be interpreted as decimal values.
 */
public interface Decimal<V>
    where V <: ValueSymbol<V> & Equatable<V> & LessOrEqual<V>
{
    /**
     * Convert a number to an unsigned signal of values of a given width.
     *
     * @param x
     * @param width
     * @return The corresponding signal
     */
    static func UnsignedDecToSignal(x : Int64, width : Int64) : Signal<V>
    /**
     * Convert a number to an signed signal of values of a given width.
     *
     * @param x
     * @param width
     * @return The corresponding signal
     */
    static func SignedDecToSignal(x : Int64, width : Int64) : Signal<V>
    /**
     * Convert a number to an signal of values of a given width.
     *
     * @param x
     * @param width
     * @param signed
     * @return The corresponding signal
     */
    static func DecToSignal(
        x  : Int64, width : Int64, signed : Bool
    ) : Signal<V>
}
/**
 * Make a signal circuit for a signal converted from a decimal number.
 *
 * @param x
 * @param width
 * @param signed
 * @return The interfaced hypergraph containing the circuit
 */
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
/**
 * Given an array of numbers, convert them into an array of corresponding
 * signals.
 *
 * @param vs The numbers
 * @param width
 * @param signed
 * @return The array of corresponding signals
 */
func MakeDecimalSignalArray<V>(
    vs : Array<Int64>, width: Int64, signed: Bool
) : Array<Signal<V>>
    where
        V <: ValueSymbol<V> & Equatable<V> & LessOrEqual<V> & Decimal<V>
{
    map({ v : Int64 => V.DecToSignal(v, width, signed)}, vs)
}
/**
 * Convert an array of numbers into an open waveform of signals.
 *
 * @param xs
 * @param width
 * @param signed
 * @return The circuit containing the open waveform
 */
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
/**
 * Convert an array of numbers into a closed waveform of signals.
 *
 * @param xs
 * @param width
 * @param signed
 * @return The circuit containing the closed waveform
 */
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
/**
 * Convert an array of numbers into an infinite waveform of signals.
 *
 * @param xs
 * @param width
 * @param signed
 * @return The circuit containing the infinite waveform
 */
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
/**
 * Use a signal circuit corresponding to a number.
 *
 * @param x
 * @param width
 * @param signed
 * @return The output wire of the signal
 */
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
/**
 * Use a signal circuit corresponding to zero.
 *
 * @param width
 * @return The output wire of the zero signal
 */
public func UseInstantZero<V, G>(width!: Int64) : Wire<V, G>
    where
        V <: ValueSymbol<V> & Equatable<V> & LessOrEqual<V> & Decimal<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
{
    UseSignalFromInt(0, width: width, signed: false)
}
/**
 * Use an open waveform circuit corresponding to an array of numbers.
 *
 * @param xs
 * @param input The input wire to the waveform
 * @param width
 * @param signed
 * @return The output wire of the waveform
 */
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
/**
 * Use a closed waveform circuit corresponding to an array of numbers.
 *
 * @param xs
 * @param width
 * @param signed
 * @return The output wire of the waveform
 */
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
/**
 * Use an infinite waveform circuit corresponding to an array of numbers.
 *
 * @param xs
 * @param width
 * @param signed
 * @return The output wire of the waveform
 */
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
/**
 * Use an infinite waveform circuit that constantly outputs zero.
 *
 * @param width
 * @return The output wire of the zero waveform
 */
public func UseConstantZero<V, G>(width!: Int64) : Wire<V, G>
    where
        V <: ValueSymbol<V> & Equatable<V> & LessOrEqual<V> & Decimal<V>,
        G <: PrimitiveSymbol<V> & Equatable<G>
{
    UseInfiniteWaveformFromInt([0], width: width, signed: false)
}
/**
 * Interface containing functions for using signals and waveforms converted
 * from decimal.
 */
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
/**
 * Use a simple register with an initial value converted from a number.
 *
 * @param initial
 * @param width
 * @param signed
 * @param input The input to the register
 * @return The output wire of the register
 */
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
/**
 * Perform register guarded feedback with an initial value converted from a
 * number.
 *
 * @param initial
 * @param width
 * @param signed
 * @param input The wire to feed back
 * @param incoming The wire to connect the feedback to
 */
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