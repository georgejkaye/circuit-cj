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
func ComputeLongestChain<T>(elements : HashSet<T>, bot : T, top : T) : Int64
    where T <: LessOrEqual<T> & Hashable & Equatable<T>
{
    func ComputeLongestChainLength(currentElement : T) : Int64 {
        if(currentElement == bot) {
            0
        } else {
            let nexts = HashSet<Int64>()
            for(e in elements) {
                if(e != currentElement && e <= currentElement) {
                    nexts.put(1 + ComputeLongestChainLength(e))
                }
            }
            fold_left<Int64, Int64>({ acc, cur => max(acc, cur) }, 0, nexts)
        }
    }
    ComputeLongestChainLength(top)
}

func ComputeOrderIntersectionOp<T>(
    elements : HashSet<T>,
    orderFn : (T, T) -> Bool,
    rankFn : (T, T) -> T,
    op : String
) : (T, T) -> T where T <: Hashable & Equatable<T> & LessOrEqual<T> & ToString {
    { lhs : T, rhs : T =>
        AssertElementInCollection(lhs, elements)
        AssertElementInCollection(rhs, elements)
        AssertCollectionHasLengthAtLeast<T>(elements, 1)
        if(lhs == rhs) {
            lhs
        } else {
            let lhsElements = HashSet<T>()
            let rhsElements = HashSet<T>()
            for(t in elements) {
                if(orderFn(t, lhs)) {
                    lhsElements.put(t)
                }
                if(orderFn(t, rhs)) {
                    rhsElements.put(t)
                }
            }
            lhsElements.removeIf({ t : T => !rhsElements.contains(t) })
            let res = match(fold_left<T>(rankFn, lhsElements)){
                case Some(x) => x
                case None    => throw IncompleteLatticeException(lhs, rhs, op)
            }
            res
        }
    }
}
func ComputeMeet<T>(elements : HashSet<T>) : (T, T) -> T where T <: LessOrEqual<T> & Hashable & Equatable<T> & ToString {
    ComputeOrderIntersectionOp(elements, { lhs, rhs => lhs <= rhs}, { lhs, rhs => min(lhs, rhs) }, "\u{2227}")
}
func ComputeJoin<T>(elements : HashSet<T>) : (T, T) -> T where T <: LessOrEqual<T> & Hashable & Equatable<T> & ToString {
    ComputeOrderIntersectionOp(elements, { lhs, rhs => rhs <= lhs }, { lhs, rhs => max(lhs, rhs) },  "\u{2228}")
}
func ComputeBottom<T>(elements : HashSet<T>) : T where T <: LessOrEqual<T> & Hashable & Equatable<T> {
    fold_left<T>({ acc, cur => min(acc, cur) }, elements).getOrThrow()
}
func ComputeTop<T>(elements : HashSet<T>) : T where T <: LessOrEqual<T> & Hashable & Equatable<T> {
    fold_left<T>({ acc, cur => max(acc, cur) }, elements).getOrThrow()
}
func BinaryFunctionToHashMap<T, U, V>(
    lhsElements : HashSet<T>,
    rhsElements : HashSet<U>,
    fn : (T, U) -> V
) : HashMap<T, HashMap<U, V>> where  T <: Hashable & Equatable<T>, U <: Hashable & Equatable<U> {
    let outerMap = HashMap<T, HashMap<U, V>>()
    for(l in lhsElements) {
        let innerMap = HashMap<U, V>()
        for(r in rhsElements) {
            innerMap.put(r, fn(l, r))
        }
        outerMap.put(l, innerMap)
    }
    outerMap
}
public struct FiniteLattice<T> where T <: LessOrEqual<T> & Equatable<T> & Hashable & ToString {
    let cachedCombinations = HashMap<Int64, ArrayList<Array<T>>>()
    let longestChain : Int64
    public let elements: HashSet<T>
    public let meet: HashMap<T, HashMap<T, T>>
    public let join: HashMap<T, HashMap<T, T>>
    public let bot : T
    public let top : T
    public init (elements : HashSet<T>) {
        this.elements = elements
        this.meet = BinaryFunctionToHashMap(elements, elements, ComputeMeet(elements))
        this.join = BinaryFunctionToHashMap(elements, elements, ComputeJoin(elements))
        this.bot = ComputeBottom(elements)
        this.top = ComputeTop(elements)
        this.longestChain = ComputeLongestChain<T>(elements, bot, top)
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
    public func Join(lhs : T, rhs : T) {
        AssertElementInCollection(lhs, this.elements)
        AssertElementInCollection(rhs, this.elements)
        this.join.get(lhs).getOrThrow().get(rhs).getOrThrow()
    }
    public func Meet(lhs : T, rhs : T) {
        AssertElementInCollection(lhs, this.elements)
        AssertElementInCollection(rhs, this.elements)
        this.meet.get(lhs).getOrThrow().get(rhs).getOrThrow()
    }
    public func JoinPowers(lhs: Array<T>, rhs: Array<T>) {
        AssertArraysSameLength<T, T>(lhs, rhs)
        map2<T, T, T>({ lhs, rhs => this.Join(lhs, rhs) }, lhs, rhs)
    }
    public func MeetPowers(lhs: Array<T>, rhs: Array<T>) {
        AssertArraysSameLength<T, T>(lhs, rhs)
        map2<T, T, T>({ lhs, rhs => this.Meet(lhs, rhs) }, lhs, rhs)
    }
    public func LTEPowers(lhs: Array<T>, rhs: Array<T>) {
        AssertArraysSameLength<T, T>(lhs, rhs)
        fold_left2({ acc, lhs, rhs => acc && lhs <= rhs }, true, lhs, rhs)
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
    where V <: ValueSymbol & Equatable<V> & LessOrEqual<V>, G <: PrimitiveSymbol<V> & Equatable<G>
{
    public let specificationImplementation : HashMap<Specification<V>, ((Array<Array<V>>) -> Array<V>)>
        = HashMap<Specification<V>, ((Array<Array<V>>) -> Array<V>)>()
    public Signature(
        public let name : String,
        public let latticeStructure: FiniteLattice<V>,
        public let gateInterpretation: (G) -> ((Array<Array<V>>) -> Array<V>),
        public let toDec: (Array<V>, Bool) -> Option<Int64>
    ) {}
    public func Join(v: V, u: V): V {
        this.latticeStructure.Join(v, u)
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
