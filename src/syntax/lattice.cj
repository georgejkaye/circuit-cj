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
func GetAllPermutations<V>(
    elements: HashSet<V>, width: Int64
): Array<Signal<V>>
    where V <: ValueSymbol<V>
{
    // Assign an arbitrary order to the elements
    let elementsArray = Array(elements)
    if (width == 0) {
        Array<Signal<V>>()
    } else if (width == 1) {
        mapCollection({ v : V => Signal([v]) }, elements)
    } else {
        let smaller = GetAllPermutations(elements, width - 1)
        let current = ArrayList<Signal<V>>()
        Array<Signal<V>>(smaller.size * elements.size){
            i : Int64 =>
                let elemToAppend = elementsArray[i / smaller.size]
                let smallerToExtend = smaller[i % smaller.size]
                Signal(append(smallerToExtend.GetValues(), elemToAppend))
        }
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
func ComputeLongestChain<V>(elements : HashSet<V>, bot : V, top : V) : Int64
    where V <: LessOrEqual<V> & Hashable & Equatable<V> & ToString
{
    AssertElementInCollection<V>(bot, elements)
    func ComputeLongestChainLength(currentElement : V) : Int64 {
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
func ComputeOrderIntersectionOp<V>(
    elements : HashSet<V>,
    intersection : LatticeIntersection
) : HashMap<V, HashMap<V, V>>
    where
        V <: Hashable & Equatable<V> & LessOrEqual<V> & ToString
{
    // Get the functions that determine the direction we go in the lattice
    // and how to rank the resulting candidates
    let (orderFn, rankFn) = match(intersection) {
        // The join is the lowest intersection greater than each element
        case JOIN =>
            (
                { lhs : V, rhs : V => rhs <= lhs },
                { lhs : V, rhs : V => min(lhs, rhs) }
            )
        // The meet is the greatest intersection lower than each element
        case MEET =>
            (
                { lhs : V, rhs : V => lhs <= rhs },
                { lhs : V, rhs : V => max(lhs, rhs) }
            )
    }
    // Create the hash map we are going to use to store the results
    let outerMap = HashMap<V, HashMap<V, V>>()
    for(lhs in elements) {
        let innerMap = HashMap<V, V>()
        for(rhs in elements) {
            let element =
                if(lhs == rhs) {
                    // If elements are equal, then they are already intersected
                    lhs
                } else {
                    let lhsElements = HashSet<V>()
                    let rhsElements = HashSet<V>()
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
                    lhsElements.removeIf({ t : V => !rhsElements.contains(t) })
                    // If there are no common elements, then there is no
                    // intersection: this poset is not a lattice
                    AssertLengthIsGreaterThanOrEqualTo<V>(lhsElements, 1)
                    // Find the 'best' candidate (i.e. greatest/lowest)
                    fold_left<V>(rankFn, lhsElements)
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
func ComputeBottom<V>(elements : HashSet<V>) : V
    where V <: LessOrEqual<V> & Hashable & Equatable<V> & ToString
{
    AssertLengthIsGreaterThanOrEqualTo(elements, 1)
    fold_left<V>({ acc, cur => min(acc, cur) }, elements)
}
/**
 * Compute the top element of a partially ordered set: the element that
 * is greater than all the others
 *
 * @param elements
 * @return The top element of the set
 */
func ComputeTop<V>(elements : HashSet<V>) : V
    where V <: LessOrEqual<V> & Hashable & Equatable<V> & ToString
{
    AssertLengthIsGreaterThanOrEqualTo(elements, 1)
    fold_left<V>({ acc, cur => max(acc, cur) }, elements)
}
/**
 * Compute the join (least upper bound) function of a partially ordered set
 * Throws an exception if there is no such function.
 *
 * @param elements
 * @return The join function of the set
 */
func ComputeJoin<V>(elements : HashSet<V>) : HashMap<V, HashMap<V, V>>
    where V <: LessOrEqual<V> & Hashable & Equatable<V> & ToString
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
func ComputeMeet<V>(elements : HashSet<V>) : HashMap<V, HashMap<V, V>>
    where V <: LessOrEqual<V> & Hashable & Equatable<V> & ToString
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
 */
public struct FiniteLattice<V>
    where V <: ValueSymbol<V>
{
    let elements: HashSet<V>
    let join: HashMap<V, HashMap<V, V>>
    let meet: HashMap<V, HashMap<V, V>>
    let bot : V
    let top : V
    // We cache powers since we often access the same ones a lot
    let cachedPowers = HashMap<Int64, Array<Signal<V>>>()
    // The longest chain in the lattice is used for computing fixpoints
    let longestChain : Int64
    public init (elements : HashSet<V>) {
        this.elements = elements
        this.meet = ComputeMeet(elements)
        this.join = ComputeJoin(elements)
        this.bot = ComputeBottom(elements)
        this.top = ComputeTop(elements)
        this.longestChain = ComputeLongestChain(elements, bot, top)
    }
    /**
     * @return The set of elements in this lattice
     */
    public func GetElements() : HashSet<V> {
        this.elements
    }
    /**
     * Enumerate the powers of elements in this lattice of width i
     *
     * @param i The width of the powers to enumerate
     * @return A list of powers of elements in this lattice
     */
    public func EnumerateSignals(i: Int64): Array<Signal<V>> {
        match (this.cachedPowers.get(i)) {
            case Some(s) => s
            case None =>
                let result = GetAllPermutations(this.elements, i)
                this.cachedPowers.put(i, result)
                result
        }
    }
    /**
     * Given an array of ports of arbitrary widths, enumerate all the possible
     * permutations of inputs to these ports.
     *
     * @param ports The array of ports
     * @return An array in which element i is an array of inputs for each
     *             input wire
     */
    public func EnumerateInputs(
        ports : Array<Port>,
        fixed!: HashMap<Int64, HashSet<Signal<V>>> = HashMap()
    ) : Array<Array<Signal<V>>> {
        // First compute all the possible permutations for each input wire
        // inputPowers[i] is the array of possible signals along wire i
        let inputPowers = mapi(
            { p : Port, i : Int64 =>
                match(fixed.get(i)){
                    case None     => EnumerateSignals(p.GetWidth())
                    case Some(fx) => Array(fx)
                }
        }, ports
        )
        // We need to return an array containing each possible permutation
        // of elements in inputPowers. To do this, we generate an array in which
        // each element is computed as
        //
        //      inputs[i][j] = inputPowers[j][(i / a) mod b]
        //
        // where a is the product of the number of perms for each input < j,
        // and b is the number of permutations of size j.
        //
        // We compute the divsors in advance
        let divisors = Array<Int64>(ports.size){
            i : Int64 => Product(inputPowers, { ps => ps.size }, end: i)
        }
        // The total combinations is also a big product
        let totalCombinations = Product(inputPowers, { ps => ps.size })
        // Now we can define the array of all permutations
        Array<Array<Signal<V>>>(totalCombinations){
            i : Int64 =>
                Array<Signal<V>>(ports.size){
                    j : Int64 =>
                        let possiblePowers = inputPowers[j]
                        let totalPerms = possiblePowers.size
                        let combinationIndex = if(totalPerms == 1) {
                            0
                        } else {
                            (i / divisors[j]) % totalPerms
                        }
                        possiblePowers[combinationIndex]
                }
        }
    }
    /**
     * Compute the join of two elements in this lattice
     *
     * @param lhs
     * @param rhs
     * @return The join of lhs and rhs
     */
    public func Join(lhs : V, rhs : V) : V {
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
    public func Meet(lhs : V, rhs : V) : V {
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
    public func Join(lhs: Array<V>, rhs: Array<V>) : Array<V> {
        AssertSameLength<V, V>(lhs, rhs)
        map2<V, V, V>({ lhs, rhs => this.Join(lhs, rhs) }, lhs, rhs)
    }
    /**
     * Compute the pointwise meet of two powers of elements in this lattice
     *
     * @param lhs
     * @param rhs
     * @return The pointwise meet of lhs and rhs
     */
    public func Meet(lhs: Array<V>, rhs: Array<V>) : Array<V> {
        AssertSameLength<V, V>(lhs, rhs)
        map2<V, V, V>({ lhs, rhs => this.Meet(lhs, rhs) }, lhs, rhs)
    }
    /**
     * Compute lhs <= rhs for two elements in the lattice
     *
     * @param lhs
     * @param rhs
     * @return lhs <= rhs
     */
    public func LTE(lhs : V, rhs : V) : Bool {
        lhs <= rhs
    }
    /**
     * Compute pointwise lhs <= rhs for two powers of elements in the lattice
     *
     * @param lhs
     * @param rhs
     * @return lhs <= rhs
     */
    public func LTE(lhs: Array<V>, rhs: Array<V>) : Bool {
        AssertSameLength(lhs, rhs)
        fold_left2({ acc, lhs, rhs => acc && lhs <= rhs }, true, lhs, rhs)
    }
    /**
     * Compute pointwise lhs <= rhs for two powers of elements in the lattice
     *
     * @param lhs
     * @param rhs
     * @return lhs <= rhs
     */
    public func LTE(lhs : Signal<V>, rhs: Signal<V>) : Bool {
        this.LTE(lhs.GetValues(), rhs.GetValues())
    }
    /**
     * Compute pointwise lhs <= rhs for two powers of powers of
     * elements in the lattice
     *
     * @param lhs
     * @param rhs
     * @return lhs <= rhs
     */
    public func LTE(lhs: Array<Signal<V>>, rhs : Array<Signal<V>>) : Bool {
        AssertSameLength(lhs, rhs)
        fold_left2(
            { acc, lhs, rhs => acc && this.LTE(lhs, rhs)}, true, lhs, rhs
        )
    }
    /**
     * Get the longest chain in the lattice structure induced on powers of V.
     * This means the length of the longest sequence bot <= ... <= top.
     *
     * @param i The size of the tuples in the induced lattice
     * @return The length of the longest chain
     */
    public func GetLongestChain(i : Int64) : Int64 {
        this.longestChain * i
    }
}