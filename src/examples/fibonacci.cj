/**
 * examples/fibonacci.cj
 *
 * A naive fibonacci circuit to compute the nth
 * fibonacci number
 *
 * @author George Kaye
 * @since 0.1
 */

package examples

/**
 * Naive fibonacci circuit to compute the nth fibonacci number
 * @param n The fibonacci number to compute (from s0 = 0, s1 = 1, s2 = 1...)
 * @param width The width of the number buses
 */
public func Fibonacci(n : Int64, width : Int64) : InterfacedHypergraph {
    let output = if (n == 0) {
        Zero(width)
    } else if (n == 1) {
        UnsignedValueFromInt(1, width: width)
    } else {
        let fiba = UseSubcircuit_1(Fibonacci(n - 2, width), Array<Wire>())
        let fibb = UseSubcircuit_1(Fibonacci(n - 1, width), Array<Wire>())
        RippleAdder(
            fiba,
            fibb,
            Zero(1)
        )[0]
    }
    MakeSubcircuit(
        Array<InterfaceWire>(),
        [
            InterfaceWire(output, "F")
        ],
        "fibonacci_${n}"
    )
}