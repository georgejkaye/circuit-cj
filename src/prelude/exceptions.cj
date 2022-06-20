package prelude

import debug.*

public class NoAssociatedValueException <: Exception {
    public init(function : String) {
        ErrorMsg(function, "Tried to access a value for a key that doesn't exist")
    }
}