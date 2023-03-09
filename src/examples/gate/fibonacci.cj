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
        sig.UseInstantZero(width: width)
    } else if (n == 1) {
        sig.UseSignalFromInt(1, width: width, signed: false)
    } else {
        let fiba = UseSubcircuit_1(Fibonacci(n - 2, width), Array<Wire_>())
        let fibb = UseSubcircuit_1(Fibonacci(n - 1, width), Array<Wire_>())
        UseRippleAdder(
            fiba,
            fibb,
            sig.UseInstantZero(width: 1)
        )[0]
    }
    MakeSubcircuit(
        Array<InterfaceWire_>(),
        [InterfaceWire(output, "Z")],
        "fibonacci_${n}"
    )
}