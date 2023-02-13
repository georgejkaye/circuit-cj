/**
 * syntax/signature.cj
 *
 * Definition of signatures, containing components in a circuit
 */
package syntax

from std import collection.HashSet, collection.HashMap

func GetAllPermutations<T>(elems: HashSet<T>, i: Int64): ArrayList<Array<T>> where T <: Equatable<T> & Hashable {
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
    where T <: ValueSymbol & Equatable<T>
{
    let currentChain = ArrayList<T>()
    currentChain.append(bot)
    func ComputeLongestChainIteration(longest : Int64) : Int64 {
        let currentElement = currentChain[0]
        var currentLongest = longest
        for(e in elements) {
            if(e != currentElement && lte(currentElement, e)){
                currentLongest = if(e == top){
                    if(currentChain.size > longest){
                        currentChain.size
                    } else {
                        currentLongest
                    }
                } else {
                    currentChain.prepend(e)
                    let subcallLongest = ComputeLongestChainIteration(longest)
                    currentChain.remove(0)
                    subcallLongest
                }
            }
        }
        currentLongest
    }
    ComputeLongestChainIteration(0)
}
public struct FiniteLattice<T> where T <: ValueSymbol & Equatable<T> {
    let cachedCombinations = HashMap<Int64, ArrayList<Array<T>>>()
    let longestChain : Int64
    public let elements: HashSet<T>
    public let bot: T
    public let top: T
    public let lte: (T, T) -> Bool
    public let join: (T, T) -> T
    public init (
        elements : HashSet<T>,
        bot : T,
        top : T,
        lte : (T, T) -> Bool,
        join : (T, T) -> T
    ) {
        this.elements = elements
        this.bot = bot
        this.top = top
        this.lte = lte
        this.join = join
        // this.longestChain = ComputeLongestChain(elements, bot, top, lte)
        // AssertElementInCollection(bot, elements)
        // AssertElementInCollection(top, elements)
        this.longestChain = 0
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
public interface PrimitiveSymbol<V>
    <: Specifiable<V> & HasName & ToString & Hashable
    where V <: ValueSymbol & Equatable<V> {
    func GetEnhancedName(n: Int64, w: Int64): String
}
public class Signature<V, G> <: HasName & ToString
    where V <: ValueSymbol & Equatable<V>, G <: PrimitiveSymbol<V> & Equatable<G>
{
    public let specificationImplementation : HashMap<Specification<V>, ((Array<Array<V>>) -> Array<V>)>
        = HashMap<Specification<V>, ((Array<Array<V>>) -> Array<V>)>()
    public Signature(
        public let name : String,
        public let latticeStructure: FiniteLattice<V>,
        public let gateInterpretation: (G) -> ((Array<Array<V>>) -> Array<V>),
        public let toDec: (Array<V>, Bool) -> Option<Int64>
    ) {}
    public func JoinValues(v: V, u: V): V {
        this.latticeStructure.join(v, u)
    }
    public func JoinPowers(v: Array<V>, u: Array<V>): Array<V> {
        this.latticeStructure.JoinPowers(v, u)
    }
    public func GetJoin(i : Int64) : (Array<V>, Array<V>) -> Array<V> {
        { lhs : Array<V>, rhs : Array<V> => this.latticeStructure.JoinPowers(lhs, rhs) }
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
