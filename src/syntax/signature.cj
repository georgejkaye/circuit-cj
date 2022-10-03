/**
 * syntax/signature.cj
 *
 * Definition of signatures, containing components in a circuit
 */

package syntax

from std import collection.HashSet, collection.HashMap

import assertions.*

func GetAllPermutations<T>(elems : HashSet<T>, i : Int64) : ArrayList<Array<T>> where T <: Equatable<T>, T <: Hashable {
    if (i == 0){
        ArrayList<Array<T>>()
    } else {
        let smaller = GetAllPermutations(elems, i - 1)
        let current = ArrayList<Array<T>>()
        for(perm in smaller) {
            for(elem in elems) {
                let extended = ArrayList<T>(perm)
                extended.append(elem)
                current.append(extended.toArray())
            }
        }
        current
    }
}
public struct FiniteLattice<T> where T <: Equatable<T>, T <: LE<T>, T <: Hashable, T <: ToString {
    let cachedCombinations = HashMap<Int64, ArrayList<Array<T>>>()
    public FiniteLattice(
        public let elements : HashSet<T>,
        public let bot : T,
        public let top : T,
        public let join : (T, T) -> T
    ){}
    public func EnumeratePowers(i : Int64) : ArrayList<Array<T>> {
        match(this.cachedCombinations.get(i)) {
            case Some(s) => s
            case None =>
                let result = GetAllPermutations(this.elements, i)
                this.cachedCombinations.put(i, result)
                result
        }
    }
    public func JoinPowers(lhs : Array<T>, rhs : Array<T>) {
        AssertArraysSameLength<T, T>(lhs, rhs)
        map2({l : T, r : T => this.join(l, r)}, lhs, rhs)
    }
    public func LTEPowers(lhs : Array<T>, rhs : Array<T>) {
        AssertArraysSameLength<T, T>(lhs, rhs)
        fold_left2({ acc : Bool, l : T, r : T => acc && (l <= r) }, true, lhs, rhs)
    }
}

public struct Primitive<T> <: Equatable<Primitive<T>> & Hashable & ToString & Specifiable & HasName
    where T <: Equatable<T>, T <: LE<T>, T <: Hashable, T <: ToString
{
    static var nextPrimitiveId : Int64 = 0
    public let id : Int64
    public let lattice : FiniteLattice<T>
    public let spec : Specification
    public let table : (Array<T>) -> Array<T>
    public init(
        lattice : FiniteLattice<T>,
        name : String,
        inputs : Array<String>,
        outputs : Array<String>,
        table : (Array<T>) -> Array<T>
    ){
        AssertTableMonotone<T>(lattice, inputs.size(), table)
        this.id = nextPrimitiveId
        nextPrimitiveId++
        this.lattice = lattice
        this.table = table
        this.spec = Specification(
            name,
            map({ s : String => Port(1, s) }, inputs),
            map({ s : String => Port(1, s) }, outputs)
        )
    }
    public func GetId() : Int64 {
        this.id
    }
    public operator func ==(rhs : Primitive<T>) : Bool {
        this.id == rhs.GetId()
    }
    public operator func !=(rhs : Primitive<T>) : Bool {
        !(this.id == rhs.GetId())
    }
    public func hashCode() : Int64 {
        this.id
    }
    public func toString() : String {
        this.spec.toString()
    }
    public func GetName() : String {
        this.spec.GetName()
    }
    public func GetInputPorts() : Array<Port> {
        this.spec.inputPorts
    }
    public func GetNoInputs() : Int64 {
        this.GetInputPorts().size
    }
    public func GetOutputPorts() : Array<Port> {
        this.spec.outputPorts
    }
    public func GetNoOutputs() : Int64 {
        this.GetOutputPorts().size
    }
    /**
     * Get a name for an 'enhanced' version of this primitive, i.e. one
     * with thicker input wires (where the primitive will be applied bitwise)
     * and multiple input wires (where the primitive will be folded across them)
     *
     * @param n The number of inputs to the composite gate
     * @param w The width of each input to the composite gate
     * @return The name of the composite gate
     */
    public func GetEnhancedName(n : Int64, w : Int64) : String {
        "${this.GetName()}${n}_${w}"
    }
}

public struct Signature<T> where T <: Equatable<T>, T <: LE<T>, T <: Hashable, T <: ToString {
    public Signature(
        public let lattice : FiniteLattice<T>,
        public let primitives : HashSet<Primitive<T>>
    ) {}
}
