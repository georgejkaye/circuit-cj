package arithmetic

import components.*
import debug.*

class InputsNotSameWidthException <: Exception {
    init(function : String, w : WireEnd, v : WireEnd) {
        ErrorMsg(function, "${w} and ${v} need to be the same size")
    }
}