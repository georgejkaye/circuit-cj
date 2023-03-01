/**
 * utils/arrays.cj
 *
 * Functions for handling arrays and general collections
 *
 * @author George Kaye
 * @since 0.2
 */
package utils
/**
 * Given an array and an element, create a new array with the contents of the
 * first array preceeded by the new element.
 *
 * @param x
 * @param ys
 * @return The array x ++ ys
 */
public func prepend<T>(x : T, ys : Array<T>) {
    Array<T>(ys.size + 1){
        i : Int64 =>
            if(i == 0) {
                x
            } else {
                ys[i-1]
            }
    }
}
/**
 * Given an array and an element, create a new array with the contents of the
 * first array followed by the new element.
 *
 * @param xs
 * @param y
 * @return The array xs ++ u
 */
public func append<T>(xs : Array<T>, y : T) {
    Array<T>(xs.size + 1){
        i : Int64 =>
            if(i == xs.size) {
                y
            } else {
                xs[i]
            }
    }
}
/**
 * Given two arrays, create a new array with their concatenation.
 *
 * @param xs
 * @param ys
 * @return The concatenation of xs and ys
 */
public func concat<T>(xs : Array<T>, ys : Array<T>) {
    Array<T>(xs.size + ys.size){
        i : Int64 =>
            if(i < xs.size) {
                xs[i]
            } else {
                ys[i - xs.size]
            }
    }
}
/**
 * Get a bespokely printed string of a collection.
 *
 * @param collection
 * @param printFn The function that generates a string for an element
 * @param openingBracket
 * @param closingBracket
 * @param delimiter
 */
public func printCollection<T>(
    collection : Collection<T>,
    printFn : (T) -> String,
    openingBracket!: String = "{",
    closingBracket!: String = "}",
    delimiter!: String = ",",
    newline!: Bool = false
) : String {
    let str = foldi_left(
        {acc : String, cur : T, i : Int64 =>
            let delimiter = if(i != collection.size - 1) {
                "${delimiter}${if(newline){"\n"}}"
            } else {
                ""
            }
            "${acc}${printFn(cur)}${delimiter}"

        }, "", collection
    )
    "${openingBracket}${str}${closingBracket}"
}
/**
 * Get a bespokely printed string of an array.
 *
 * @param array
 * @param printFn The function that generates a string for an element
 * @param openingBracket
 * @param closingBracket
 * @param delimiter
 */
public func printArray<T>(
    array : Array<T>,
    printFn : (T) -> String,
    openingBracket!: String = "[",
    closingBracket!: String = "]",
    delimiter!: String = ",",
    newline!: Bool = false
) : String {
    printCollection(
        array, printFn, openingBracket: openingBracket,
        closingBracket: closingBracket, delimiter: delimiter, newline: newline
    )
}