/**
 * examples/fibonacci.cj
 *
 * A naive fibonacci circuit to compute the nth
 * fibonacci number
 *
 * @author George Kaye
 * @since 0.1
 */

package examples.gate

/**
 * Naive fibonacci circuit to compute the nth fibonacci number
 * @param n The fibonacci number to compute (from s0 = 0, s1 = 1, s2 = 1...)
 * @param width The width of the number buses
 */
public func Fibonacci(n : Int64, width : Int64) : Circuit_ {
    let output = if (n == 0) {
        sig.Zero(width)
    } else if (n == 1) {
        sig.UseUnsignedSignalFromInt(1, width)
    } else {
        let fiba = sig.UseSubcircuit_1(Fibonacci(n - 2, width), Array<Wire_>())
        let fibb = sig.UseSubcircuit_1(Fibonacci(n - 1, width), Array<Wire_>())
        UseRippleAdder(
            fiba,
            fibb,
            sig.Zero(1)
        )[0]
    }
    sig.MakeSubcircuit(
        Array<InterfaceWire_>(),
        [InterfaceWire(output, "Z")],
        "fibonacci_${n}"
    )
}