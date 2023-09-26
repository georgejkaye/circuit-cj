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
import syntax.BuildWaveform
/**
 * Make a signal circuit for a signal converted from a decimal number.
 *
 * @param x
 * @param width
 * @param signed
 * @return The interfaced hypergraph containing the circuit
 */
func MakeSignal<V, G>(
    x : Int64, width!: Int64, signed!: Bool
) : InterfacedHypergraph<V, G>
    where
        V <: ValueSymbol<V> & Decimal<V>,
        G <: PrimitiveSymbol<V, G>
{
    let signal = V.DecToSignal(x, width: width, signed: signed)
    MakeSignal(signal)
}
/**
 * Convert an array of numbers into an open waveform of signals.
 *
 * @param xs
 * @param width
 * @param signed
 * @return The circuit containing the open waveform
 */
func MakeOpenWaveform<V, G>(
    signals!: Array<Int64>, width!: Int64, signed!: Bool
) : InterfacedHypergraph<V, G>
    where
        V <: ValueSymbol<V> & Decimal<V>,
        G <: PrimitiveSymbol<V, G>
{
    let waveform = BuildWaveform<V>(
        signals: signals, width: width, signed: signed
    )
    MakeOpenWaveform(waveform: waveform)
}
/**
 * Convert an array of numbers into a closed waveform of signals.
 *
 * @param xs
 * @param width
 * @param signed
 * @return The circuit containing the closed waveform
 */
func MakeClosedWaveform<V, G>(
    signals!: Array<Int64>, width!: Int64, signed!: Bool
) : InterfacedHypergraph<V, G>
    where V <: ValueSymbol<V> & Decimal<V>, G <: PrimitiveSymbol<V, G>
{
    let waveform = BuildWaveform<V>(
        signals: signals, width: width, signed: signed
    )
    MakeClosedWaveform(waveform: waveform)
}
/**
 * Convert an array of numbers into an infinite waveform of signals.
 *
 * @param xs
 * @param width
 * @param signed
 * @return The circuit containing the infinite waveform
 */
func MakeInfiniteWaveform<V, G>(
    signals!: Array<Int64>, width!: Int64, signed!: Bool
) : InterfacedHypergraph<V, G>
    where V <: ValueSymbol<V> & Decimal<V>, G <: PrimitiveSymbol<V, G>
{
    let waveform = BuildWaveform<V>(
        signals: signals, width: width, signed: signed
    )
    MakeInfiniteWaveform(waveform: waveform)
}
/**
 * Use a signal circuit corresponding to a number.
 *
 * @param x
 * @param width
 * @param signed
 * @return The output wire of the signal
 */
func UseSignal<V, G>(
    x : Int64, width!: Int64, signed!: Bool
) : Wire<V, G>
    where V <: ValueSymbol<V> & Decimal<V>, G <: PrimitiveSymbol<V, G>
{
    let signal = V.DecToSignal(x, width: width, signed: signed)
    UseSignal(signal)
}
/**
 * Use a signal circuit corresponding to zero.
 *
 * @param width
 * @return The output wire of the zero signal
 */
func UseInstantZero<V, G>(width!: Int64) : Wire<V, G>
    where V <: ValueSymbol<V> & Decimal<V>, G <: PrimitiveSymbol<V, G>
{
    UseSignal(0, width: width, signed: false)
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
func UseOpenWaveform<V, G>(
    signals!: Array<Int64>, input!: Wire<V, G>, width!: Int64, signed!: Bool
) : Wire<V, G>
    where V <: ValueSymbol<V> & Decimal<V>, G <: PrimitiveSymbol<V, G>
{
    let waveform = BuildWaveform<V>(
        signals: signals, width: width, signed: signed
    )
    UseOpenWaveform(waveform: waveform, input: input)
}
/**
 * Use a closed waveform circuit corresponding to an array of numbers.
 *
 * @param xs
 * @param width
 * @param signed
 * @return The output wire of the waveform
 */
func UseClosedWaveform<V, G>(
    signals!: Array<Int64>, width!: Int64, signed!: Bool
) : Wire<V, G>
    where V <: ValueSymbol<V> & Decimal<V>, G <: PrimitiveSymbol<V, G>
{
    let waveform = BuildWaveform<V>(
        signals: signals, width: width, signed: signed
    )
    UseClosedWaveform(waveform: waveform)
}
/**
 * Use an infinite waveform circuit corresponding to an array of numbers.
 *
 * @param xs
 * @param width
 * @param signed
 * @return The output wire of the waveform
 */
func UseInfiniteWaveform<V, G>(
    signals!: Array<Int64>, width!: Int64, signed!: Bool
) : Wire<V, G>
    where V <: ValueSymbol<V> & Decimal<V>, G <: PrimitiveSymbol<V, G>
{
    let waveform = BuildWaveform<V>(
        signals: signals, width: width, signed: signed
    )
    UseInfiniteWaveform(waveform: waveform)
}
/**
 * Use an infinite waveform circuit that constantly outputs zero.
 *
 * @param width
 * @return The output wire of the zero waveform
 */
public func UseConstantZero<V, G>(width!: Int64) : Wire<V, G>
    where V <: ValueSymbol<V> & Decimal<V>, G <: PrimitiveSymbol<V, G>
{
    UseInfiniteWaveform(signals: [0], width: width, signed: false)
}
/**
 * Interface containing functions for using signals and waveforms converted
 * from decimal.
 */
public interface DecimalSignalUser<V, G>
    where V <: ValueSymbol<V> & Decimal<V>, G <: PrimitiveSymbol<V, G>
{
    func UseSignal(
        x : Int64, width!: Int64, signed!: Bool
    ) : Wire<V, G> {
        UseSignal<V, G>(x, width: width, signed: signed)
    }
    func UseInstantZero(width!: Int64) : Wire<V, G> {
        UseInstantZero<V, G>(width: width)
    }
    func UseConstantZero(width!: Int64) : Wire<V, G> {
        UseConstantZero<V, G>(width: width)
    }
    func UseOpenWaveform(
        signals!: Array<Int64>, input!: Wire<V, G>, width!: Int64, signed!: Bool
    ) : Wire<V, G> {
        UseOpenWaveform<V, G>(
            signals: signals, input: input, width: width, signed: signed
        )
    }
    func UseClosedWaveform(
        signals!: Array<Int64>, width!: Int64, signed!: Bool
    ) : Wire<V, G> {
        UseClosedWaveform<V, G>(
            signals: signals, width: width, signed: signed
        )
    }
    func UseInfiniteWaveform(
        signals!: Array<Int64>, width!: Int64, signed!: Bool
    ) : Wire<V, G> {
        UseInfiniteWaveform<V, G>(
            signals: signals, width: width, signed: signed
        )
    }
}
extend Signature<V, G> <: DecimalSignalUser<V, G>
    where V <: ValueSymbol<V> & Decimal<V>, G <: PrimitiveSymbol<V, G>
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
    initial!: Int64,
    width!: Int64,
    signed!: Bool,
    input!: Wire<V, G>
) : Wire<V, G>
    where V <: ValueSymbol<V> & Decimal<V>, G <: PrimitiveSymbol<V, G>
{
    let signal = V.DecToSignal(initial, width: width, signed: signed)
    UseSimpleRegister(initial: signal, input: input)
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
    input : Wire<V, G>, incoming: Wire<V, G>,
    initial!: Int64, signed!: Bool
) : Wire<V, G>
    where V <: ValueSymbol<V> & Decimal<V>, G <: PrimitiveSymbol<V, G>
{
    let signal = V.DecToSignal(initial, width: input.GetWidth(), signed: signed)
    RegisterGuardedFeedback(input, incoming, initial: signal)
}