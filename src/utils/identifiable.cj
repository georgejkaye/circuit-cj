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
public class Counter {
    var nextId = 0
    public func GetNext() : Int64 {
        let id = nextId
        nextId++
        id
    }
}