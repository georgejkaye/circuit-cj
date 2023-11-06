/**
 * components/wires.cj
 *
 * Definition of wires, mutable pointers to
 * vertices. These are the handles users have on vertices,
 * since vertices can be merged and replaced by operations.
 *
 * @author George Kaye
 * @since 0.2
 */
package components
/**
 * A wire has an id and a mutable vertex
 */
public class Wire<V, G>
    <: Identifiable<Wire<V, G>> & ToString & ContainsVertex<V, G> &
        HasWidth & HasOptionalName & HasGraph<V, G>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    let id : Int64 = GetNextId()
    var vertex : Vertex<V, G>
    public init(v : Vertex<V, G>) {
        this.vertex = v
    }
    public func SetVertex(v : Vertex<V, G>) : Unit {
        let owner = v.GetGraph()
        this.vertex = v
    }
    public func GetName() : Option<String> {
        this.vertex.GetName()
    }
    public func GetId() : Int64 {
        this.id
    }
    public func GetWidth() : Int64 {
        this.vertex.GetWidth()
    }
    public func toString() : String {
        "w${this.id} - ${this.vertex}"
    }
    public func GetVertex() : Vertex<V, G> {
        this.vertex
    }
    public func GetGraph() : Hypergraph<V, G> {
        this.vertex.GetGraph()
    }
    /**
     * Get the least significant bit (bit 0) of a wire.
     *
     * @param w The wire to get the lsb from
     * @return The least significant bit of the wire
     */
    public func Lsb() : Wire<V, G> {
        this.LsbAndMsbs()[0]
    }
    /**
     * Get the most significant bits (not bit 0) of a wire.
     *
     * @param w The wire to get the msbs from
     * @return The most significant bits of the wire
     */
    public func Msbs() : Wire<V, G> {
        this.LsbAndMsbs()[1]
    }
    /**
     * Get the most significant bit (bit n-1) of a wire.
     *
     * @param w The wire to get the msb from
     * @return The most significant bit of the wire
     */
    public func Msb() : Wire<V, G> {
        this.LsbsAndMsb()[1]
    }
    /**
     * Get the least significant bits (not bit n-1) of a wire.
     *
     * @param w The wire to get the lsbs from
     * @return The leasts significant bits of the wire
     */
    public func Lsbs() : Wire<V, G> {
        this.LsbsAndMsb()[0]
    }
    /**
     * Split a wire so that its least significant bit is a separate wire.
     *
     * @param w The wire to split
     * @return A tuple (lsb, msbs)
     */
    public func LsbAndMsbs() : (Wire<V, G>, Wire<V, G>) {
        let splits = Split(this, [1, this.GetWidth() - 1])
        (splits[0], splits[1])
    }
    /**
     * Split a wire so that its most significant bit is a separate wire.
     *
     * @param w The wire to split
     * @return A tuple (lsbs, msb)
     */
    public func LsbsAndMsb() : (Wire<V, G>, Wire<V, G>) {
        let splits = Split(this, [this.GetWidth() - 1, 1])
        (splits[0], splits[1])
    }
    /**
     * Extract a given bit from a wire by splitting it into its constituent bits
     * and returning the appropriate one. Bits are numbered starting with the
     * lsb as 0.
     *
     * @param w The wire to extract from
     * @param i The bit to extract
     * @return The specified bit of the wire
     */
    public func Get(i : Int64) : Wire<V, G> {
        AssertHasWidthAtLeast(this, i)
        let width = this.GetWidth()
        if (i == 0) {
            let ws = Split(this, [1, width - 1])
            ws[0]
        } else if (i == width-1) {
            let ws = Split(this, [width - 1, 1])
            ws[1]
        } else {
            let ws = Split(this, [i, 1, width - i - 1])
            ws[1]
        }
    }
}
public interface ContainsWire<V, G> <: HasWidth & ContainsVertex<V, G>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    func GetWire() : Wire<V, G>
}
extend Wire<V, G> <: ContainsWire<V, G> {
    public func GetWire() : Wire<V, G> {
        this
    }
}
/**
 * Make a wire (and underlying vertex) of a given width.
 *
 * @param width The width of the wire
 * @return The wire
 */
public func UseWire<V, G>(width : Int64) : Wire<V, G>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    let vertex = Vertex(width, None<Hypergraph<V, G>>)
    Wire(vertex)
}
/**
 * Make an array of wires all of a given width.
 *
 * @param n The number of wires to create
 * @param width The width of the wire
 * @return The array of wires
 */
public func UseWires<V, G>(n : Int64, width!: Int64) : Array<Wire<V, G>>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    AssertStrictlyPositive(n)
    Array<Wire<V, G>>(n, { i : Int64 => UseWire(width) })
}
/**
 * Make an array of wires of given widths.
 *
 * @param widths The array of widths for the wires
 * @return The array of wires
 */
public func UseWires<V, G>(widths : Array<Int64>) : Array<Wire<V, G>>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    AssertNonEmpty(widths)
    map({ i : Int64 => UseWire(i) }, widths)
}
/**
 * Interface for accessing wire making functions without needing to
 * specify the generics, since these can't be determined from the arguments
 */
public interface WireUser<V, G>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    func UseWire(width : Int64) : Wire<V, G> {
        UseWire<V, G>(width)
    }
    func UseWires(n : Int64, width!: Int64) : Array<Wire<V, G>> {
        UseWires<V, G>(n, width: width)
    }
    func UseWires(widths : Array<Int64>) : Array<Wire<V, G>> {
        UseWires<V, G>(widths)
    }
}
extend Signature<V, G> <: WireUser<V, G>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{}
/**
 * Make an edge and get the wires corresponding to its targets.
 *
 * @param label The label to give this edge
 * @param sources The array of source vertices
 * @param targets The array of target vertices
 * @param graph The optional owner of this edge
 * @return The array of wires corresponding to the new edge's targets
 */
func UseEdge<V, G>(
    label : Label<V, G>,
    sources : Array<Vertex<V, G>>,
    targets : Array<Vertex<V, G>>,
    subgraph : Option<InterfacedHypergraph<V, G>>,
    owner : Hypergraph<V, G>
) : Array<Wire<V, G>>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    let newEdge = owner.AddNewEdge(label, sources, targets, subgraph)
    map({ t => Wire(t.GetVertex()) }, newEdge.GetTargets())
}
/**
 * Make an edge with fresh targets, and get the wires corresponding to them.
 *
 * @param label The label to give this edge
 * @param sources The array of verted objects
 * @param targets The array of width objects
 * @param graph The optional owner of this edge
 * @return The array of wires corresponding to the new edge's targets
 */
public func UseEdgeWithNewOutputs<V, G, T>(
    label : Label<V, G>,
    sources : Array<T>,
    graph : Option<InterfacedHypergraph<V, G>>,
    owner : Option<Hypergraph<V, G>>,
    nameTargets!: Bool = false
) : Array<Wire<V, G>>
    where
        V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>,
        T <: ContainsVertex<V, G>
{
    let sourceVertices = map({ t : T => t.GetVertex() }, sources)
    let sourceOwner = MergeHypergraphs(sourceVertices, initial: owner)
    let actualOwner = match(sourceOwner) {
        case None => Hypergraph<V, G>()
        case Some(f) => f
    }
    let targetVertices = map(
        { p : Port =>
            let name = if(nameTargets) {
                p.GetName()
            } else {
                None<String>
            }
            actualOwner.AddNewVertex(p.GetWidth(), name: name) },
        label.GetOutputPorts()
    )
    UseEdge<V, G>(label, sourceVertices, targetVertices, graph, actualOwner)
}
/**
 * Merge two vertices together, such that any edges that had either vertex
 * as a source or target is updated with the merged vertex
 *
 * @param v The vertex to merge into
 * @param w The vertex to be merged and removed
 * @return A tuple (merged vertex, removed vertex)
 */
public func MergeWires<V, G>(
    v : Wire<V, G>, w : Wire<V, G>, instant!: Bool
) : Unit
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    v.GetVertex().MergeVertex(w.GetVertex(), instant: instant)
    w.SetVertex(v.GetVertex())
}
/**
 * Split a wire into multiple wires with given widths, using a bundler edge.
 * The new widths must sum to the width of the original wire.
 *
 * @param t The wire object to split
 * @param vs The array of widths to split this wire into
 * @return The array of split wires
 */
public func Split<V, G, T>(w : T, vs : Array<Int64>) : Array<Wire<V, G>>
    where
        V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>,
        T <: ContainsWire<V, G> & ToString
{
    AssertHasWidth(w, Sum(vs))
    UseEdgeWithNewOutputs<V, G, T>(
        BUNDLER([w.GetWidth()], vs),
        [w],
        None<InterfacedHypergraph<V, G>>,
        w.GetGraph()
    )
}
/**
 * Split a wire into two wires at a given point using a bundler edge.
 *
 * @param w The wire to split
 * @param l The width of the 'left' output wire
 * @return The two output wires
 */
public func SplitAt<V, G, T>(w : T, left: Int64) : (Wire<V, G>, Wire<V, G>)
    where
        V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>,
        T <: ContainsWire<V, G> & ToString
{
    let r = w.GetWire().GetWidth() - left
    let split = Split(w, [left, r])
    (split[0], split[1])
}
/**
 * Split a wire into a given number of wires of equal size using a bundler edge.
 *
 * @param w The wire to split
 * @param into The number of equal sized wires to split into
 * @return The array of split wires
 */
public func SplitInto<V, G, T>(w : T, into: Int64) : Array<Wire<V, G>>
        where
        V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>,
        T <: ContainsWire<V, G> & ToString
{
    let width = AssertMultipleOf(w.GetWidth(), into)
    Split(w, Array<Int64>(into, { _ => width }))
}
/**
 * Split a wire into its constituent bits, using a bundler edge.
 *
 * @param w The wire to split
 * @return The array of split wires
 */
public func SplitAll<V, G, T>(w : T) : Array<Wire<V, G>>
    where
        V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>,
        T <: ContainsWire<V, G> & ToString
{
    if(w.GetWidth() == 1) {
        [w.GetWire()]
    } else {
        Split(w, Array<Int64>(w.GetWidth(), { i : Int64 => 1}))
    }
}
/**
 * Combine an array of wires into one wire with width the sum of the original
 * wires.
 *
 * @param ws The array of wires to combine
 * @return The combined wire
 */
public func Combine<V, G, T>(ws : Array<T>) : Wire<V, G>
    where
        V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>,
        T <: ContainsWire<V, G> & ToString
{
    AssertLengthIsGreaterThanOrEqualTo(ws, 1)
    if(ws.size == 1) {
        ws[0].GetWire()
    } else {
        let widths = map({ t : T => t.GetWidth() }, ws)
        UseEdgeWithNewOutputs(
            BUNDLER(widths, [Sum(ws, { t => t.GetWidth() })]),
            ws,
            None,
            ws[0].GetGraph()
        )[0]
    }
}
/**
 * Combine two wires into one wire with width the sum of the original two wires.
 *
 * @param lhs The 'left' wire to combine
 * @param rhs The 'right' wire to combine
 * @return The combined wire
 */
public func Combine<V, G, T>(lhs : T, rhs : T) : Wire<V, G>
    where
        V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>,
        T <: ContainsWire<V, G> & ToString
{
    Combine<V, G, T>([lhs, rhs])
}
/**
 * Replicate a signal into a wire of a given width.
 *
 * @param a The input wire
 * @param w The number of times to replicate the signal
 * @return The replicated wire
 */
public func Replicate<V, G>(a : Wire<V, G>, w : Int64) : Wire<V, G>
    where
        V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    Combine(Array<Wire<V, G>>(w, { i : Int64 => a }))
}
/**
 * An interface wire is a wire with an optional name. These are
 * used to specify the names of interface ports on a subcircuit
 */
public class InterfaceWire<V, G>
    <: ContainsWire<V, G> & ToString & ContainsVertex<V, G> &
        HasPort & HasGraph<V, G>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    public InterfaceWire(
        let wire : Wire<V, G>,
        let name : Option<String>
    ){}
    public init(
        w : Wire<V, G>,
        name : String
    ){
        this(w, Some(name))
    }
    public init(
        w : Wire<V, G>
    ){
        this(w, None<String>)
    }
    public func GetWire() : Wire<V, G> {
        this.wire
    }
    public func GetVertex() : Vertex<V, G> {
        this.wire.GetVertex()
    }
    public func toString() : String {
        "${this.wire} (${name})"
    }
    public func GetWidth() : Int64 {
        this.wire.GetWidth()
    }
    public func GetName() : Option<String> {
        this.name
    }
    public operator func ==(rhs : HasPort) {
        this.wire.GetWidth() == rhs.GetWidth() && this.name == rhs.GetName()
    }
    public operator func !=(rhs : HasPort) {
        !(this == rhs)
    }
    public func GetGraph() : Hypergraph<V, G> {
        this.wire.GetGraph()
    }
}
/**
 * Create an array of named wires, given arrays of wires and names.
 *
 * @param wires The array of wires
 * @param names The array of names
 * @return The array of interface wires
 */
public func NameWires<V, G>(
    wires : Array<Wire<V, G>>,
    names : Array<String>
) : Array<InterfaceWire<V, G>>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    AssertSameLength(wires, names)
    map2(
        { w : Wire<V, G>, name : String => InterfaceWire(w, name) },
        wires, names
    )
}
/**
 * Create an array of named wires, given an array of wires and a function from
 * indices to names.
 *
 * @param wires The array of wires
 * @param f The function from wire indices to names
 * @return The array of interface wires
 */
public func NameWires<V, G>(
    wires : Array<Wire<V, G>>,
    f : (Int64) -> String
) : Array<InterfaceWire<V, G>>
    where V <: ValueSymbol<V>, G <: PrimitiveSymbol<V, G>
{
    Array<InterfaceWire<V, G>>(
        wires.size,
        { i : Int64 => InterfaceWire(wires[i], f(i)) }
    )
}
extend Wire<V, G> <: Drawable<V, G> {
    public func WriteDotToFile(
        file : String, depth!: Int64 = 0,
        debug!: Bool = false, expandSignals!: Bool = false
    ) : Unit {
        this.GetGraph().WriteDotToFile(
            file, depth: depth, debug: debug, expandSignals: expandSignals
        )
    }
}
extend Wire<V, G> <: DecimalDrawable where V <: Decimal<V> {
    public func WriteDotToFile(
        file : String, depth!: Int64 = 0, signed!: Bool, debug!: Bool = false,
        expandSignals!: Bool = false
    ) : Unit {
        this.GetGraph().WriteDotToFile(
            file, depth: depth, signed: signed, debug: debug,
            expandSignals: expandSignals
        )
    }
}