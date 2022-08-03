/**
 * graphs/element.cj
 * 
 * @author George Kaye
 * @since 0.2
 */

package graphs

/**
 * Global ids for objects
 */
var nextId = 0
public func GetNextId() : Int64 {
    let id = nextId
    nextId++
    id
}

public interface Identifiable {
    func GetId() : Int64
}

public interface Ownable<T> {
    func GetOwner() : Option<T> 
    func SetOwner(t : T) : Unit
    func RemoveOwner() : Unit
}