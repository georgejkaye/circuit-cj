package components

import debug.*

public class NotEnoughBitsException <: Exception {
    init(function: String, attempted : Int64, actual : Int64, required : Int64) {
        ErrorMsg(function, "Attempted to represent ${attempted} in ${actual} bits, but ${required} are required")
    }
}

public class NegativeNumberException <: Exception {
    init(function : String, number : Int64) {
        ErrorMsg(function, "Attempted to represent negative number ${number} in an unsigned value")
    }
}