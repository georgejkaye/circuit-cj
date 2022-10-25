/**
 * syntax/signature.cj
 *
 * Definition of signatures, containing components in a circuit
 */
package syntax

from std import collection.HashSet, collection.HashMap
import assertions.*

func GetAllPermutations<T>(elems: HashSet<T>, i: Int64): ArrayList<Array<T>> where T <: Equatable<T>, T <: Hashable {
    if (i == 0) {
        ArrayList<Array<T>>()
    } else {
        let smaller = GetAllPermutations(elems, i - 1)
        let current = ArrayList<Array<T>>()
        for (perm in smaller) {
            for (elem in elems) {
                let extended = ArrayList<T>(perm)
                extended.append(elem)
                current.append(extended.toArray())
            }
        }
        current
    }
}
public interface ValueSymbol <: Hashable & HasName & ToString {}
func ComputeLongestChain<T>(elements : HashSet<T>, bot : T, top : T, lte : (T, T) -> Bool) : Int64
    where T <: ValueSymbol, T <: Equatable<T>
{
    println("Computing longest chain in ${elements}")
    let currentChain = ArrayList<T>()
    currentChain.append(bot)
    var longest = 0
    func ComputeLongestChainIteration() : Unit {
        println("current ${currentChain}")
        let currentElement = currentChain[0]
        for(e in elements) {
            if(e != currentElement && lte(currentElement, e)){
                if(e == top){
                    if(currentChain.size > longest){
                        longest = currentChain.size
                        println(currentChain)
                    }
                } else {
                    currentChain.prepend(e)
                    ComputeLongestChainIteration()
                    currentChain.remove(0)
                }
            }
        }
    }
    ComputeLongestChainIteration()
    longest
}
public struct FiniteLattice<T> where T <: ValueSymbol, T <: Equatable<T> {
    let cachedCombinations = HashMap<Int64, ArrayList<Array<T>>>()
    let longestChain : Int64
    public FiniteLattice(
        public let elements: HashSet<T>,
        public let bot: T,
        public let top: T,
        public let lte: (T, T) -> Bool,
        public let join: (T, T) -> T
    ) {
        AssertElementInCollection(bot, elements)
        AssertElementInCollection(top, elements)
        this.longestChain = ComputeLongestChain(elements, bot, top, lte)
    }
    public func EnumeratePowers(i: Int64): ArrayList<Array<T>> {
        match (this.cachedCombinations.get(i)) {
            case Some(s) => s
            case None =>
                let result = GetAllPermutations(this.elements, i)
                this.cachedCombinations.put(i, result)
                result
        }
    }
    public func JoinPowers(lhs: Array<T>, rhs: Array<T>) {
        AssertArraysSameLength<T, T>(lhs, rhs)
        map2({l: T, r: T => this.join(l, r)}, lhs, rhs)
    }
    public func LTEPowers(lhs: Array<T>, rhs: Array<T>) {
        AssertArraysSameLength<T, T>(lhs, rhs)
        fold_left2({acc: Bool, l: T, r: T => acc && (this.lte(l, r))}, true, lhs, rhs)
    }
    /**
     * Get the longest chain in the lattice structure
     * induced on powers of V
     *
     * @param i The size of the tuples in the induced lattice
     * @return The length of the longest chain
     */
    public func GetLongestChain(i : Int64) : Int64 {
        this.longestChain * i
    }
}
public interface PrimitiveSymbol<V> <: Specifiable<V> & HasName & ToString & Hashable where V <: ValueSymbol,
    V <: Equatable<V> {
    func GetEnhancedName(n: Int64, w: Int64): String
}
public struct Signature<V, G> <: HasName & ToString where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G> {
    public Signature(
        public let name : String,
        public let latticeStructure: FiniteLattice<V>,
        public let gateInterpretation: (G) -> ((Array<V>) -> Array<V>),
        public let toDec: (Array<V>, Bool) -> Option<Int64>
    ) {}
    public func JoinValues(v: V, u: V): V {
        this.latticeStructure.join(v, u)
    }
    public func JoinPowers(v: Array<V>, u: Array<V>): Array<V> {
        this.latticeStructure.JoinPowers(v, u)
    }
    public func LTEPowers(v: Array<V>, u: Array<V>): Bool {
        this.latticeStructure.LTEPowers(v, u)
    }
    public func GetBottom() : V {
        this.latticeStructure.bot
    }
    public func GetLongestChain(i : Int64) : Int64 {
        this.latticeStructure.GetLongestChain(i)
    }
    public func GetName() : String {
        this.name
    }
    public func toString() : String {
        this.GetName()
    }
}
