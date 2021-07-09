package examples

import circuits.*

/**
 * Naive fibonacci circuit to compute the nth fibonacci number
 * @param n The fibonacci number to compute (from s0 = 0, s1 = 1, s2 = 1...)
 * @param width The width of the number buses
 */
func Fibonacci(n : Int64, width!: Int64) : Hypergraph {
    if(n == 0){
        UnsignedValueFromInt(0, width: width)
    } else if (n == 1) {
        UnsignedValueFromInt(1, width: width)
    } else {
        Plus(Fibonacci(n - 1, width: width), Fibonacci(n - 2, width: width))
    }
}