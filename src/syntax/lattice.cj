/**
 * syntax/lattice.cj
 *
 * Contains the definition of finite lattices.
 * Values in a circuit are assembled into such lattices.
 *
 * @author George Kaye
 * @since 0.3
 */
package syntax
/**
 * Given a set of elements, compute all the permutations of a given length.
 *
 * @param elements
 * @param i The length of permutations to compute
 * @return A list of all the permutations of length i
 */
func GetAllPermutations<T>(
    elements: HashSet<T>,
    i: Int64
): ArrayList<Array<T>>
    where T <: Equatable<T> & Hashable
{
    if (i == 0) {
        ArrayList<Array<T>>()
    } else {
        let smaller = GetAllPermutations(elements, i - 1)
        let current = ArrayList<Array<T>>()
        for (perm in smaller) {
            for (elem in elements) {
                let extended = ArrayList<T>(perm)
                extended.append(elem)
                current.append(extended.toArray())
            }
        }
        current
    }
}
/**
 * Given a partially ordered set of elements, compute the length of the longest
 * chain between two elements bot and top, i.e. the longest sequence
 *         bot <= v_1 <= ... <= v_2 <= top
 *
 * @param elements
 * @param bot The element at the bottom of the chain
 * @param top The element at the top of the chain
 * @return The length of the longest chain, e.g. bot <= v <= top has length 2
 */
func ComputeLongestChain<T>(elements : HashSet<T>, bot : T, top : T) : Int64
    where T <: LessOrEqual<T> & Hashable & Equatable<T> & ToString
{
    AssertElementInCollection<T>(bot, elements)
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
/**
 * The types of intersection operation in a lattice
 */
enum LatticeIntersection {
    | JOIN // Least upper bound
    | MEET // Greatest lower bound
}
/**
 * Define a function for computing the intersection of two elements in a
 * partially ordered set, i.e. either the join or meet.
 * This is defined in a curried fashion as a hashmap inside a hashmap: this
 * allows us to cache the results rather than having to compute them each time.
 * It also means that if the intersection does not exist, an exception is
 * thrown when constructing the lattice rather than when computing with it.
 *
 * @param elements
 * @param intersection The type of intersection function to compute
 * @return The intersection function
 */
func ComputeOrderIntersectionOp<T>(
    elements : HashSet<T>,
    intersection : LatticeIntersection
) : HashMap<T, HashMap<T, T>>
    where
        T <: Hashable & Equatable<T> & LessOrEqual<T> & ToString
{
    // Get the functions that determine the direction we go in the lattice
    // and how to rank the resulting candidates
    let (orderFn, rankFn) = match(intersection) {
        // The join is the lowest intersection greater than each element
        case JOIN =>
            (
                { lhs : T, rhs : T => rhs <= lhs },
                { lhs : T, rhs : T => min(lhs, rhs) }
            )
        // The meet is the greatest intersection lower than each element
        case MEET =>
            (
                { lhs : T, rhs : T => lhs <= rhs },
                { lhs : T, rhs : T => max(lhs, rhs) }
            )
    }
    // Create the hash map we are going to use to store the results
    let outerMap = HashMap<T, HashMap<T, T>>()
    for(lhs in elements) {
        let innerMap = HashMap<T, T>()
        for(rhs in elements) {
            let element =
                if(lhs == rhs) {
                    // If elements are equal, then they are already intersected
                    lhs
                } else {
                    let lhsElements = HashSet<T>()
                    let rhsElements = HashSet<T>()
                    // Find all elements greater/lower than the two elements
                    for(t in elements) {
                        if(orderFn(t, lhs)) {
                            lhsElements.put(t)
                        }
                        if(orderFn(t, rhs)) {
                            rhsElements.put(t)
                        }
                    }
                    // Find all the common elements
                    lhsElements.removeIf({ t : T => !rhsElements.contains(t) })
                    // If there are no common elements, then there is no
                    // intersection: this poset is not a lattice
                    AssertCollectionHasLengthAtLeast<T>(lhsElements, 1)
                    // Find the 'best' candidate (i.e. greatest/lowest)
                    fold_left<T>(rankFn, lhsElements).getOrThrow()
                }
            innerMap.put(rhs, element)
        }
        outerMap.put(lhs, innerMap)
    }
    outerMap
}
/**
 * Compute the bottom element of a partially ordered set: the element that
 * is lower than all the others
 *
 * @param elements
 * @return The bottom element of the set
 */
func ComputeBottom<T>(elements : HashSet<T>) : T
    where T <: LessOrEqual<T> & Hashable & Equatable<T> & ToString
{
    AssertCollectionHasLengthAtLeast(elements, 1)
    fold_left<T>({ acc, cur => min(acc, cur) }, elements).getOrThrow()
}
/**
 * Compute the top element of a partially ordered set: the element that
 * is greater than all the others
 *
 * @param elements
 * @return The top element of the set
 */
func ComputeTop<T>(elements : HashSet<T>) : T
    where T <: LessOrEqual<T> & Hashable & Equatable<T> & ToString
{
    AssertCollectionHasLengthAtLeast(elements, 1)
    fold_left<T>({ acc, cur => max(acc, cur) }, elements).getOrThrow()
}
/**
 * Compute the join (least upper bound) function of a partially ordered set
 * Throws an exception if there is no such function.
 *
 * @param elements
 * @return The join function of the set
 */
func ComputeJoin<T>(elements : HashSet<T>) : HashMap<T, HashMap<T, T>>
    where T <: LessOrEqual<T> & Hashable & Equatable<T> & ToString
{
    ComputeOrderIntersectionOp(elements, JOIN)
}
 /**
 * Compute the meet (greatest lower bound) function of a partially ordered set
 * Throws an exception if there is no such function.
 *
 * @param elements
 * @return The meet function of the set
 */
func ComputeMeet<T>(elements : HashSet<T>) : HashMap<T, HashMap<T, T>>
    where T <: LessOrEqual<T> & Hashable & Equatable<T> & ToString
{
    ComputeOrderIntersectionOp(elements, MEET)
}
/**
 * Struct for finite lattices, an partially ordered set such that each two
 * elements have:
 * - A least upper bound ('join'): the lowest c such that a <= c and b <= c
 * - A greatest lower bound ('meet'): the highest c such that c <= a and c <= b
 *
 * Given a partially ordered set with enough structure, the join and meet can be
 * computed: this is attempted when defining a FiniteLattice and an exception
 * thrown if this is not possible.
 *
 * Finite lattices are always 'bounded' in the sense that there exists elements
 * bot and top such that bot <= a and a <= top for any a.
 *
 * See also https://en.wikipedia.org/wiki/Lattice_order
 *
 */
public struct FiniteLattice<T>
    where T <: LessOrEqual<T> & Equatable<T> & Hashable & ToString
{
    public let elements: HashSet<T>
    public let join: HashMap<T, HashMap<T, T>>
    public let meet: HashMap<T, HashMap<T, T>>
    public let bot : T
    public let top : T
    // We cache powers since we often access the same ones a lot
    let cachedPowers = HashMap<Int64, ArrayList<Array<T>>>()
    // The longest chain in the lattice is used for computing fixpoints
    let longestChain : Int64
    public init (elements : HashSet<T>) {
        this.elements = elements
        this.meet = ComputeMeet(elements)
        this.join = ComputeJoin(elements)
        this.bot = ComputeBottom(elements)
        this.top = ComputeTop(elements)
        this.longestChain = ComputeLongestChain(elements, bot, top)
    }
    /**
     * Enumerate the powers of elements in this lattice of width i
     *
     * @param i The width of the powers to enumerate
     * @return A list of powers of elements in this lattice
     */
    public func EnumeratePowers(i: Int64): ArrayList<Array<T>> {
        match (this.cachedPowers.get(i)) {
            case Some(s) => s
            case None =>
                let result = GetAllPermutations(this.elements, i)
                this.cachedPowers.put(i, result)
                result
        }
    }
    /**
     * Compute the join of two elements in this lattice
     *
     * @param lhs
     * @param rhs
     * @return The join of lhs and rhs
     */
    public func Join(lhs : T, rhs : T) : T {
        AssertElementInCollection(lhs, this.elements)
        AssertElementInCollection(rhs, this.elements)
        this.join.get(lhs).getOrThrow().get(rhs).getOrThrow()
    }
    /**
     * Compute the meet of two elements in this lattice
     *
     * @param lhs
     * @param rhs
     * @return The meet of lhs and rhs
     */
    public func Meet(lhs : T, rhs : T) : T {
        AssertElementInCollection(lhs, this.elements)
        AssertElementInCollection(rhs, this.elements)
        this.meet.get(lhs).getOrThrow().get(rhs).getOrThrow()
    }
    /**
     * Compute the pointwise join of two powers of elements in this lattice
     *
     * @param lhs
     * @param rhs
     * @return The pointwise join of lhs and rhs
     */
    public func Join(lhs: Array<T>, rhs: Array<T>) : Array<T> {
        AssertArraysSameLength<T, T>(lhs, rhs)
        map2<T, T, T>({ lhs, rhs => this.Join(lhs, rhs) }, lhs, rhs)
    }
    /**
     * Compute the pointwise meet of two powers of elements in this lattice
     *
     * @param lhs
     * @param rhs
     * @return The pointwise meet of lhs and rhs
     */
    public func Meet(lhs: Array<T>, rhs: Array<T>) : Array<T> {
        AssertArraysSameLength<T, T>(lhs, rhs)
        map2<T, T, T>({ lhs, rhs => this.Meet(lhs, rhs) }, lhs, rhs)
    }
    /**
     * Compute lhs <= rhs for two elements in the lattice
     *
     * @param lhs
     * @param rhs
     * @return lhs <= rhs
     */
    public func LTE(lhs : T, rhs : T) : Bool {
        lhs <= rhs
    }
    /**
     * Compute pointwise lhs <= rhs for two powers of elements in the lattice
     *
     * @param lhs
     * @param rhs
     * @return lhs <= rhs
     */
    public func LTE(lhs: Array<T>, rhs: Array<T>) : Bool {
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