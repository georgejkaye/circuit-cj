/**
 * helpers.cj
 *
 * This file contains some helper functions used within the library
 */
package debug

from std import collection.ArrayList

public func test(){
    return true
}

/**
 * Generic includes function for arraylists
 * Presumably this will make its way into the standard library at some point
 * @param xs The arraylist to search
 * @param a  The element to search for
 * @return Whether this element is in the arraylist
 */
public func includes<T>(xs : ArrayList<T>, a : T) where T <: Equatable<T> {
    for(x in xs){
        if(x == a){
            return true
        }
    }
    return false
}
/**
 * Generic includes function for the left element in an arraylist of pairs
 * Presumably this will make its way into the standard library at some point
 * @param xs The arraylist of pairs to search
 * @param t  The element to search for in the first element of the pairs
 * @return Whether this element is in the arraylist
 */
public func includesPairL<T,U>(xs : ArrayList<(T , U)>, t : T) where T <: Equatable<T> {
    for((x, y) in xs){
        if(x == t){
            return true
        }
    }
    return false
}
/**
 * Generic includes function for the right element in an arraylists of pairs
 * Presumably this will make its way into the standard library at some point
 * @param xs The arraylist of pairs to search
 * @param u  The element to search for in the second element of the pairs
 * @return Whether this element is in the arraylist
 */
public func includesPairR<T,U>(xs : ArrayList<(T , U)>, u : U) where U <: Equatable<U> {
    for((x, y) in xs){
        if(y == u){
            return true
        }
    }
    return false
}
public func includesPair<T,U>(xs : ArrayList<(T, T)>, t : T) where T <: Equatable<T>, U <: Equatable<U> {
    for ((x, y) in xs){
        if(x == t || y == t){
            return true
        }
    }
    return false
}
/**
 * Pretty print a list with a given string printing function
 * @param xs The arraylist to print
 * @param f  The function to print each element
 * @return Whether this element is in the arraylist
 */
public func PrintList<T>(xs : ArrayList<T>, f : (T) -> String) {
    var str = "["
    for(x in xs){
        str = "${str} ${f(x)}"
    }
    str = "${str} ]"
    str
}
/**
 * Pretty print a list of pairs with a given string printing function for each element in the pair
 * @param xs The arraylist to print
 * @param f  The function to print each element
 * @return Whether this element is in the arraylist
 */
public func PrintListPairs<T,U>(xs : ArrayList<(T, U)>, f : (T) -> String, g : (U) -> String) where T <: ToString {
    var str = "["
    for((x, y) in xs){
        str = "${str} (${f(x)}, ${g(y)})"
    }
    str = "${str} ]"
    str
}
/**
 * Pretty print a list with a given string printing function
 * @param xs The arraylist to print
 * @param f  The function to print each element
 * @return Whether this element is in the arraylist
 */
public func PrintList<T>(xs : ArrayList<T>) where T <: ToString {
    var str = "["
    for(x in xs){
        str = "${str} ${x.toString()}"
    }
    str = "${str} ]"
    str
}
/**
 * Get the index of the first occurrence of an element in a list
 * @param xs The arraylist to searc
 * @param a  The element to search for 
 * @return The index of the first occurrence of the element in the list
 */
public func index<T>(xs : ArrayList<T>, a : T) where T <: Equatable<T> {
    for(i in 0..xs.size()){
        if(xs[i] == a){
            return Some<Int64>(i)
        }
    }
    return None<Int64>
}