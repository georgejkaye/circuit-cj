/**
 * syntax/ports.cj
 *
 * Contains the definition of ports with a width and a(n optional) name
 *
 * @author George Kaye
 * @since 0.2
 */
package syntax
/**
 * Interface for things with a width
 */
public interface HasWidth {
    func GetWidth() : Int64
}
extend Int64 <: HasWidth {
    public func GetWidth() : Int64 {
        this
    }
}
/**
 * Assert something has a width of exactly some value.
 *
 * @param t
 * @param i The desired width
 */
public func AssertHasWidth<T>(t : T, i : Int64) : Unit
    where T <: HasWidth & ToString
{
    AssertHasParameter(
        t, i, { t => t.GetWidth() }, Width
    )
}
/**
 * Assert something has a width of greater than some value.
 *
 * @param t
 * @param i The desired width
 */
public func AssertHasWidthAtLeast<T>(t : T, i : Int64) : Unit
    where T <: HasWidth & ToString
{
    AssertHasParameterGreaterThanOrEqualTo(
        t, i, { t => t.GetWidth() }, Width
    )
}
/**
 * Given two things with widths, assert that they have the same width.
 * Returns the width if so, throws an exception if not
 *
 * @param t
 * @param u
 * @return The width if t and u have the same width
 */
public func AssertBothSameWidth<T, U>(t : T, u : U) : Int64
    where T <: HasWidth & ToString, U <: HasWidth & ToString
{
    AssertBothSameParameter<T, U, Int64>(
        t, u, { t : T => t.GetWidth() }, { u : U => u.GetWidth() }, Width
    )
}
/**
 * Given an array of things with widths, assert that they are all the same
 * width. Returns the width if they are, throws an exception if they are not.
 *
 * @param xs
 * @return The width of the objects if they are all the same
 */
public func AssertAllElementsHaveSameWidth<T>(
    xs : Collection<T>, start!: Int64 = 0, end!: Int64 = xs.size,
    excluding!: HashSet<Int64> = HashSet()
) : Int64
    where T <: HasWidth & ToString
{
    AssertAllElementsHaveSameParameter<T, Int64>(
        xs, { t : T => t.GetWidth() }, Width, start: start, end: end,
        excluding: excluding
    )
}
/**
 * Given an array of things with widths, assert that they all have a given
 * width.
 *
 * @param xs
 * @param i The desired width
 */
public func AssertAllElementsHaveWidth<T>(xs : Array<T>, i : Int64) : Unit
    where T <: HasWidth & ToString
{
    AssertAllElementsHaveSameParameter<T, Int64>(
        xs, { t : T => t.GetWidth() }, Width
    )
}
/**
 * Given two arrays of things with widths, assert that they pointwise have the
 * same widths. Returns the array of widths if they do, throws an exception if
 * they do not.
 *
 * @param xs
 * @param ys
 * @return The array of widths, if they match up
 */
public func AssertArraysSameWidths<T, U>(
    xs : Array<T>, ys : Array<U>
) : Array<Int64>
    where T <: HasWidth & ToString, U <: HasWidth & ToString
{
    AssertElementsHaveParameters<T, U, Int64>(
        xs, ys, { t => t.GetWidth() }, { u => u.GetWidth() }, Width
    )
}
/**
 * Given an array of arrays of things with widths, assert that the each subarray
 * has the same width, and each array has the same width pointwise. Returns
 * the length of the subarrays if successful.
 *
 * @param xs
 * @param ys
 * @return The length of the subarrays, if successful
 */
public func AssertArrayArraysSameWidths<T>(xss : Array<Array<T>>) : Int64
    where T <: HasWidth & ToString
{
    let parentSize = xss.size
    if(parentSize > 0) {
        let childSize = AssertAllSameLength(xss)
        for(i in 0..childSize){
            AssertAllElementsHaveSameWidth(
                Array(parentSize){ j : Int64 => xss[j][i] }
            )
        }
        parentSize
    } else {
        0
    }
}
/**
 * Given an array of objects with width, get a string of their width array.
 *
 * @param array
 * @return The string of widths e.g. [1,2,3,4,...]
 */
public func PrintWidthArray<T>(array : Array<T>) : String where T <: HasWidth {
    arrayToString<T>(
        array, { t : T => "${t.GetWidth()}" },
        openingBracket: "[", closingBracket: "]", delimiter: ","
    )
}
/**
 * Interface for things with a name
 */
public interface HasName {
    func GetName() : String
}
/**
 * Interface for things with an optional name
 */
public interface HasOptionalName {
    func GetName() : Option<String>
    func GetNameString() : String {
        match(this.GetName()) {
            case None => ""
            case Some(n) => n
        }
    }
}
public func GetLongestNameLength<T>(ts : Array<T>) : Int64
    where T <: HasOptionalName
{
    max(ts, { i, t => t.GetNameString().size })
}
/**
 * A HasPort is something with a width, optional name, and string identifier
 */
public interface HasPort <: HasWidth & HasOptionalName & ToString {
    func ToPort() : Port {
        Port(this.GetWidth(), name: this.GetName())
    }
}
/**
 * A port has a width and an optional name
 */
public struct Port <: Equatable<Port> & HasPort {
    public Port(
        public let width : Int64,
        public let name!: Option<String> = None
    ){}
    public init(
        width : Int64,
        name : String
    ){
        this(width, name: Some(name))
    }
    public func toString() : String {
        let nameString = match(name) {
            case None => ""
            case Some(n) => " (${n})"
        }
        "${width}${nameString}"
    }
    public operator func ==(rhs : Port) : Bool {
        this.width == rhs.GetWidth() && this.name == rhs.GetName()
    }
    public operator func !=(rhs : Port) : Bool {
        !(this == rhs)
    }
    public func GetWidth() : Int64 {
        this.width
    }
    public func GetName() : Option<String> {
        this.name
    }
}
/**
 * Interface for things that can be specified by their input and output ports.
 */
public interface Specifiable
{
    /**
     * @return the array of input ports
     */
    func GetInputPorts() : Array<Port>
    /**
     * @param i
     * @return the ith input port
     */
    func GetInputPort(i : Int64) : Port {
        this.GetInputPorts()[i]
    }
    /**
     * @return the number of input ports
     */
    func GetArity() : Int64 {
        this.GetInputPorts().size
    }
    /**
     * @return the array of output ports
     */
    func GetOutputPorts() : Array<Port>
    /**
     * @param i
     * @return the ith output port
     */
    func GetOutputPort(i : Int64) : Port {
        this.GetOutputPorts()[i]
    }
    /**
     * @return the number of output ports
     */
    func GetCoarity() : Int64 {
        this.GetOutputPorts().size
    }
}
/**
 * Assert something specifiable has a given arity.
 *
 * @param t
 * @param n The desired arity
 */
public func AssertHasArity<T>(t : T, n : Int64) : Unit
    where T <: Specifiable & ToString
{
    AssertHasParameter(
        t, n, { t => t.GetArity() }, Inputs
    )
}
/**
 * Assert something specifiable has a given coarity.
 *
 * @param t
 * @param n The desired coarity
 */
public func AssertHasCoarity<T>(t : T, n : Int64) : Unit
    where T <: Specifiable & ToString
{
    AssertHasParameter(
        t, n, { t => t.GetCoarity() }, Outputs
    )
}