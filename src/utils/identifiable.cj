/**
 * utils/identifiable.cj
 *
 * Interface for structures with unique ids that are also used for hashing
 * and equality testing.
 *
 * @author George Kaye
 * @since 0.2
 */
package utils
/**
 * Global ids for objects
 */
var nextId = 0
public func GetNextId() : Int64 {
    let id = nextId
    nextId++
    id
}
/**
 * Interface for things with unique ids
 */
public interface Identifiable<T> <: Hashable & Equatable<T>
    where T <: Identifiable<T>
{
    func GetId() : Int64
    func hashCode() : Int64 {
        this.GetId()
    }
    operator func ==(rhs : T) : Bool {
        this.GetId() == rhs.GetId()
    }
    operator func !=(rhs : T) : Bool {
        !(this == rhs)
    }
}