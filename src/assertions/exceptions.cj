/**
 * assertions/exceptions.cj
 *
 * @author George Kaye
 * @since 0.2
 */

package assertions

/**
 * Print an error message, prepending it with [ERROR].
 *
 * @param msg The message to print
 */
public func ErrorMsg(msg : String) : Unit {
    println("[ERROR] ${msg})")
}

/**
 * Exception for when associated parameters of two objects are not equal.
 *
 * @param T The type of the first object, has ToString
 * @param U The type of the second object, has ToString
 * @param V The type of the parameter, has ToString
 */
class IncompatibleParameterException3<T,U,V> <: Exception where T <: ToString,
                                                                U <: ToString,
                                                                V <: ToString
{
    public init(
        paramType : ParamType,
        current : T,
        currentParam : V,
        target : U,
        targetParam : V
    ) {
        ErrorMsg("When checking that ${current} has the same ${paramType} as ${target}, found that ${current} has ${currentParam} while ${target} has ${targetParam}")
    }
    public init(
        paramType : ParamType,
        current: Array<T>,
        currentParams : Array<V>,
        target: Array<U>,
        targetParams : Array<V>
    ) {
        ErrorMsg("When checking that ${current} has the same ${paramType} as ${target}, found that ${current} has ${currentParams} while ${target} has ${targetParams}")
    }
}
class IncompatibleParameterException2<T, V> <: Exception where T <: ToString, V <: ToString {
    public init(
        paramType : ParamType,
        current : T,
        currentParam : V,
        targetParam : V
    ){
        ErrorMsg("When checking that ${current} has ${paramType} of value ${targetParam}, found that it has ${currentParam}")
    }
    public init(
        paramType : ParamType,
        current: Array<T>,
        currentParams : Array<V>,
        target: V
    ){
        ErrorMsg("When checking that each element of ${current} has ${paramType} of value ${target}, found that ${current} has values ${currentParams}")
    }
    public init(
        current: T,
        target: V
    ){
        ErrorMsg("When checking that ${current} is ${target}, found that it is not")
    }
}
class IncompatibleParameterException<T> <: Exception where T <: ToString {
    public init(
        paramType : ParamType,
        current : Option<T>
    ){
        ErrorMsg("When checking that ${current} is not None, found that it was None")
    }
}

/**
 * Exception for when an array is unexpectedly empty
 */
class EmptyArrayException <: Exception {
    public init() {
        ErrorMsg("Encountered an empty array when a non-empty one was expected")
    }
}

/**
 * Class for when an array should either be exactly a given length
 * or at least a given length
 *
 * @param T the type of the array, has ToString
 */
class IncompatibleArrayLengthException<T> <: Exception where T <: ToString {
    public init(xs : Array<T>, n : Int64, exact : Bool) {
        let exactText = if (exact) { "" } else { " at least"}
        ErrorMsg("Expected an array of ${exactText}length ${n} but ${xs} is of length ${xs.size()}")
    }
}

class InsufficientParameterException2<T, U> <: Exception where T <: ToString, U <: ToString {
    public init(paramType : ParamType, t : T, currentParam : U, u : U) {
        ErrorMsg("Expected ${t} to have ${paramType} of value at least ${u} but it only has ${t}")
    }
}

class InsufficientParameterException <: Exception {
    public init(i : Int64, t : Int64) {
        ErrorMsg("Expected ${i} to be greater than or equal to ${t}")
    }
}