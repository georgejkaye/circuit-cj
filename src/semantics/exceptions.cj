package semantics

import debug.*
import syntax.*

public class BadDomainException <: Exception {
    init(function : String, label : Label, required : Int64, actual : Int64) {
        ErrorMsg(function, "Evaluation of ${label.GetName()} required ${required} inputs but only had ${actual}")
    }
}