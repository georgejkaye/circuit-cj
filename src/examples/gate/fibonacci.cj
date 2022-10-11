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
        Zero(width)
    } else if (n == 1) {
        UseUnsignedSignalFromInt(1, width: width)
    } else {
        let fiba = UseSubcircuit_1(Fibonacci(n - 2, width), Array<Wire_>())
        let fibb = UseSubcircuit_1(Fibonacci(n - 1, width), Array<Wire_>())
        RippleAdder(
            fiba,
            fibb,
            Zero(1)
        )[0]
    }
    MakeSubcircuit(
        Array<InterfaceWire_>(),
        [sig.NameWire(output, "Z")],
        "fibonacci_${n}"
    )
}