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
class IncompatibleParameterException<T,U,V> <: Exception where T <: ToString, 
                                                                U <: ToString, 
                                                                V <: ToString 
{
    public init(
        paramType : ParamType,
        target : T,
        targetParam : V,
        current : U,
        currentParam : V
    ) {
        ErrorMsg("When checking that ${target} and ${current} have the same ${paramType}, found that ${target} has ${targetParam} but ${current} has ${currentParam}")
    }
    public init(
        paramType : ParamType,
        target: Array<T>,
        targetParams : Array<V>,
        current: Array<U>,
        currentParams : Array<V>
    ) {
        ErrorMsg("When checking that ${target} and ${current} have the same ${paramType}, found that ${target} has ${targetParams} but ${current} has ${currentParams}")
    }
    public init(
        paramType : ParamType,
        targetParam : T,
        current : U,
        currentParam : T
    ){
        ErrorMsg("When checking that ${current} has ${paramType} ${targetParam}, found that ${current} has ${paramType} ${currentParam}")
    }
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