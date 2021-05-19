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

external func PrintList<T>(xs : ArrayList<T>, f : (T) -> String) {
    var str = "["
    for(x in xs){
        str = "${str} ${f(x)}"
    }
    str = "${str} ]"
    str
}

external func PrintList<T>(xs : ArrayList<T>) where T <: ToString {
    var str = "["
    for(x in xs){
        str = "${str} ${x}"
    }
    str = "${str} ]"
    str
}

external func position<T>(xs : ArrayList<T>, a : T) where T <: Equatable {
    for(i in 0..xs.size()){
        if(xs[i] == a){
            return Some<Int64>(i)
        }
    }
    return None<Int64>
}