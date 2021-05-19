/**
 * helpers.cj
 *
 * This file contains some helper functions used within the library
 */
package debug

/**
 * Generic includes function for arraylists
 * Presumably this will make its way into the standard library at some point
 * @param xs The arraylist to search
 * @param a  The element to search for
 * @return Whether this element is in the arraylist
 */
external func includes<T>(xs : ArrayList<T>, a : T) where T <: Equatable {
    for(x in xs){
        if(x == a){
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
external func PrintList<T>(xs : ArrayList<T>, f : (T) -> String) {
    var str = "["
    for(x in xs){
        str = "${str} ${f(x)}"
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
external func PrintList<T>(xs : ArrayList<T>) where T <: ToString {
    var str = "["
    for(x in xs){
        str = "${str} ${x}"
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
external func index<T>(xs : ArrayList<T>, a : T) where T <: Equatable {
    for(i in 0..xs.size()){
        if(xs[i] == a){
            return Some<Int64>(i)
        }
    }
    return None<Int64>
}