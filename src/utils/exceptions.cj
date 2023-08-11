/**
 * utils/exceptions.cj
 *
 * General exceptions
 *
 * @author George Kaye
 * @since 0.2
 */
package utils
import debug.*
/**
 * Exception for when associated parameters of two objects are not equal.
 *
 * @param <T> The type of the first object
 * @param <U> The type of the second object
 * @param <V> The type of the parameter
 */
class IncompatibleParameterException3<T, U, V> <: Exception
    where T <: ToString, U <: ToString, V <: ToString
{
    public init(
        paramType : ParamType, current : T, currentParam : V,
        target : U, targetParam : V
    ) {
        ErrorMsg(
            "When checking that ${current} has the same ${paramType} as " +
            "${target}, found that ${current} has ${currentParam} while " +
            "${target} has ${targetParam}"
        )
    }
    public init(
        paramType : ParamType, current: Array<T>, currentParams : Array<V>,
        target: Array<U>, targetParams : Array<V>
    ) {
        ErrorMsg(
            "When checking that ${current} has the same ${paramType} as " +
            "${target}, found that ${current} has ${currentParams} while " +
            "${target} has ${targetParams}"
        )
    }
}
/**
 * Exception for when associated parameters of two objects are not equal.
 *
 * @param <T> The type of the object
 * @param <V> The type of the parameter
 */
class IncompatibleParameterException2<T, V> <: Exception
    where T <: ToString, V <: ToString
{
    public init(
        paramType : ParamType, current : T, currentParam : V, targetParam : V
    ){
        ErrorMsg(
            "When checking that ${current} has ${paramType} of value " +
            "${targetParam}, found that it has ${currentParam}"
        )
    }
    public init(
        paramType : ParamType, current: Collection<T>,
        currentParams : Collection<V>, target: V
    ){
        ErrorMsg(
            "When checking that each element of " +
            "${collectionToString(current)} has ${paramType} of value " +
            "${target}, found that ${collectionToString(current)} has values " +
            "${collectionToString(currentParams)}"
        )
    }
    public init(current: T, target: V){
        ErrorMsg(
            "When checking that ${current} is ${target}, found that it is not"
        )
    }
}
/**
 * Exception for when an object is not None.
 *
 * @param <T> The type of the object in an Option
 */
class IncompatibleParameterException<T> <: Exception where T <: ToString {
    public init(_ : ParamType, current : Option<T>){
        ErrorMsg(
            "When checking that ${current} is not None, found that it was None"
        )
    }
    public init(_ : T, msg : String) {
        ErrorMsg(msg)
    }
}
/**
 * Exception for when an array is unexpectedly empty.
 */
class EmptyException <: Exception {
    public init() {
        ErrorMsg(
            "Encountered an empty array but a non-empty one was expected"
        )
    }
}
/**
 * Exception for when an array is unexpectedly non-empty.
 */
class NonEmptyException <: Exception {
    public init(contents : ParamType) {
        ErrorMsg(
            "Encountered a non-empty array of ${contents} when an empty one " +
            "was expected"
        )
    }
}
/**
 * Exception for when an array should either be exactly a given length
 * or at least a given length.
 *
 * @param <T> The type of the collection
 */
class IncompatibleLengthException<T> <: Exception where T <: ToString {
    public init(xs : Collection<T>, n : Int64, exact : Bool) {
        let exactText = if (exact) { "" } else { " at least"}
        let contents = collectionToString(xs, { x => "${x}"})
        ErrorMsg(
            "Expected an array of ${exactText}length ${n} but ${contents} is " +
            "of length ${xs.size}"
        )
    }
    public init(xs : Collection<T>, multiple! : Int64) {
        let contents = collectionToString(xs, { x => "${x}"})
        ErrorMsg(
            "Expected an array of length a multiple of ${multiple} but " +
            "${contents} is of length ${xs.size}"
        )
    }
}
/**
 * Exception for when an object has an insufficiently high parameter.
 *
 * @param <T> The type of the object
 * @param <U> The type of the parameter
 */
class InsufficientParameterException2<T, U> <: Exception
    where T <: ToString, U <: ToString
{
    public init(paramType : ParamType, t : T, currentParam : U, u : U) {
        ErrorMsg("Expected ${t} to have ${paramType} of value at least ${u} " +
        "but it only has ${currentParam}")
    }
}
/**
 * Exception for when a parameter is insufficiently high.
 *
 * @param <T> The type of the parameter
 */
class InsufficientParameterException <: Exception {
    public init(i : Int64, t : Int64) {
        ErrorMsg("Expected ${i} to be greater than or equal to ${t}")
    }
}
/**
 * Exception for when a parameter is insufficiently high.
 *
 * @param <T> The type of the parameter
 */
class OversufficientParameterException <: Exception {
    public init(i : Int64, t : Int64) {
        ErrorMsg("Expected ${i} to be less than or equal to ${t}")
    }
}
/**
 * Exception for when an enum is of an unexpected variant.
 *
 * @param <T> The type of the parameter
 */
public class IncompatibleVariantException<T> <: Exception where T <: ToString {
    public init(current : T, desired : String) {
        ErrorMsg(
            "Expected ${current} to be of variant ${desired} but it is not"
        )
    }
}
/**
 * Exception for when an element is not in a collection.
 *
 * @param <T> The type of elements in the collection
 */
class ElementNotInCollectionException<T> <: Exception where T <: ToString {
    public init(wanted : T, collection : Collection<T>) {
        ErrorMsg("Expected ${wanted} to be in collection but it isn't")
    }
}
class UnreachableCodeException <: Exception {
    public init() {
        ErrorMsg("This code should be unreachable")
    }
}