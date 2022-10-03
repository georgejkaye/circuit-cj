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

from std import collection.HashSet

/**
 * A wire has an id and a mutable vertex
 */
public class Wire <: Identifiable & ToString & ContainsVertex & HasWidth {
    let id : Int64 = GetNextId()
    var vertex : Vertex
    public init(v : Vertex) {
        this.vertex = v
    }
    init(i : Int64) {
        this(Vertex(i))
    }
public func SetVertex(v : Vertex) : Unit {
        let owner = v.GetOwner()
        this.vertex = v
    }
    public func GetId() : Int64 {
        this.id
    }
    public func GetWidth() : Int64 {
        this.vertex.GetWidth()
    }
    public func toString() : String {
        "w${this.id}"
    }
    public func GetVertex() : Vertex {
        this.vertex
    }
}
public interface ContainsWire <: HasWidth & ContainsVertex {
    func GetWire() : Wire
}
extend Wire <: ContainsWire {
    public func GetWire() : Wire {
        this
    }
}
/**
 * Make a wire (and underlying vertex) of a given width
 * @param width The width of the wire
 * @return The wire
 */
public func UseWire(width : Int64) : Wire {
    let vertex = Vertex(width)
    let f = Hypergraph(HashSet<Vertex>([ vertex ]), HashSet<Edge>())
    Wire(vertex)
}
/**
 * Make an array of wires all of a given width
 * @param n The number of wires to create
 * @param width The width of the wire
 * @return The array of wires
 */
public func UseWires(n : Int64, width : Int64) : Array<Wire> {
    AssertStrictlyPositive(n)
    Array<Wire>(n, { i : Int64 => UseWire(width) })
}
/**
 * Make an array of wires of given widths
 * @param widths The array of widths for the wires
 * @return The array of wires
 */
public func UseWires(widths : Array<Int64>) : Array<Wire> {
    AssertNonEmpty(widths, "widths")
    map({ i : Int64 => UseWire(i) }, widths)
}
/**
 * An interface wire is a wire with an optional name. These are
 * used to specify the names of interface ports on a subcircuit
 */
public class InterfaceWire <: ContainsWire & ToString & ContainsVertex & Socket {
    public InterfaceWire(
        let wire : Wire,
        let name: Option<String>
    ){}
    public init(
        i : Int64,
        name: Option<String>
    ){
        this(Wire(i), name)
    }
    public init(
        w : Wire
    ){
        this(w, None<String>)
    }
    public func GetWire() : Wire {
        this.wire
    }
    public func GetVertex() : Vertex {
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
    public operator func ==(rhs : Socket) {
        this.wire.GetWidth() == rhs.GetWidth() && this.name == rhs.GetName()
    }
    public operator func !=(rhs : Socket) {
        !(this == rhs)
    }
}
/**
 * Create an array of named wires, given an array of wires and an array of names
 * @param wires The array of wires
 * @param names The array of names
 * @return The array of interface wires
 */
public func NameWires(wires : Array<Wire>, names : Array<String>) : Array<InterfaceWire> {
    AssertArraysSameLength(wires, names)
    map2({ w : Wire, name : String => InterfaceWire(w, name) }, wires, names)
}
/**
 * Create an array of named wires, given an array of wires and a function from indices to names
 * @param wires The array of wires
 * @param f The function from wire indices to names
 * @return The array of interface wires
 */
public func NameWires(wires : Array<Wire>, f : (Int64) -> String) : Array<InterfaceWire> {
    Array<InterfaceWire>(wires.size, { i : Int64 => InterfaceWire(wires[i], f(i)) })
}
/**
 * Make an edge and get the wires corresponding to its targets
 * @param label The label to give this edge
 * @param sources The array of source vertices
 * @param targets The array of target vertices
 * @param graph The optional owner of this edge
 * @return The array of wires corresponding to the new edge's targets
 */
func MakeEdge(
    label : Label,
    sources : Array<Vertex>,
    targets : Array<Vertex>,
    graph : Option<InterfacedHypergraph>
) : Array<Wire> {
    let edge = Edge(label, sources, targets, graph)
    map({t : Tentacle => Wire(t.vertex) }, edge.GetTargets())
}
/**
 * Make an edge with fresh targets, and get the wires corresponding to them
 * @param label The label to give this edge
 * @param sources The array of verted objects
 * @param targets The array of width objects
 * @param graph The optional owner of this edge
 * @return The array of wires corresponding to the new edge's targets
 */
public func UseEdgeWithNewOutputs<T>(
    label : Label,
    sources : Array<T>,
    graph : Option<InterfacedHypergraph>
) : Array<Wire> where T <: ContainsVertex {
    let sources = map({ t : T => t.GetVertex() }, sources)
    let targets = map({ p : Port => Vertex(p.GetWidth()) }, label.GetOutputPorts())
    MakeEdge(label, sources, targets, graph)
}

/**
 * Merge two vertices together, such that any edges that had either vertex
 * as a source or target is updated with the merged vertex
 * @param v The vertex to merge into
 * @param w The vertex to be merged and removed
 * @return A tuple (merged vertex, removed vertex)
 */
public func MergeWires(v : Wire, w : Wire, feedback: Bool) : Unit {
    let (retainedVertex, discardedVertex) = MergeVertices(v.GetVertex(), w.GetVertex(), feedback)
    w.SetVertex(retainedVertex)
}
/**
 * Split a wire into multiple wires with given widths, using a bundler edge. The new widths
 * must sum to the width of the original wire.
 * @param t The wire object to split
 * @param vs The array of widths to split this wire into
 * @return The array of split wires
 */
public func Split<T>(t : T, vs : Array<Int64>) : Array<Wire> where T <: ContainsWire, T <: ToString {
    AssertWireWidth<T>(t, Sum(vs))
    UseEdgeWithNewOutputs<T>(
        BUNDLER([t.GetWidth()], vs),
        [t],
        None<InterfacedHypergraph>
    )
}
/**
 * Split a wire into two wires with given widths, using a bundler edge. The two widths must
 * sum to the width of the original wire.
 * @param w The wire to split
 * @param l The width of the 'left' output wire
 * @param r The width of the 'right' output wire
 * @return The two output wires
 */
public func Split(w : Wire, l : Int64, r : Int64) : (Wire, Wire) {
    let split = Split(w, [l, r])
    (split[0], split[1])
}
/**
 * Split a wire into its constituent bits, using a bundler edge.
 * @param w The wire to split
 * @return The array of split wires
 */
public func Split(w : Wire) : Array<Wire> {
    Split(w, Array<Int64>(w.GetWidth(), { i : Int64 => 1}))
}
/**
 * Combine an array of wires into one wire with width the sum of the original wires.
 * @param ws The array of wires to combine
 * @return The combined wire
 */
public func Combine(ws : Array<Wire>) : Wire {
    let widths = map({ w : Wire => w.GetWidth() }, ws)
    UseEdgeWithNewOutputs(
        BUNDLER(widths, [Sum(widths)]),
        ws,
        None
    )[0]
}
/**
 * Combine two wires into one wire with width the sum of the original two wires.
 * @param lhs The 'left' wire to combine
 * @param rhs The 'right' wire to combine
 * @return The combined wire
 */
public func Combine(lhs : Wire, rhs : Wire) : Wire {
    Combine([lhs, rhs])
}
/**
 * Extract a given bit from a wire by splitting it into its constituent bits and
 * returning the appropriate one. Bits are numbered starting with the lsb as 0.
 * @param w The wire to extract from
 * @param i The bit to extract
 * @return The specified bit of the wire
 */
public func GetBit(w : Wire, i : Int64) : Wire{
    AssertWireHasWidthAtLeast(w, i)
    let width = w.GetWidth()
    if (i == 0) {
        let ws = Split(w, [1, width - 1])
        ws[0]
    } else if (i == width-1) {
        let ws = Split(w, [width - 1, 1])
        ws[1]
    } else {
        let ws = Split(w, [i, 1, width - i - 1])
        ws[1]
    }
}
/**
 * Get the least significant bit (bit 0) of a wire.
 * @param w The wire to get the lsb from
 * @return The least significant bit of the wire
 */
public func Lsb(w : Wire) : Wire {
    LsbAndMsbs(w)[0]
}
/**
 * Get the most significant bits (not bit 0) of a wire.
 * @param w The wire to get the msbs from
 * @return The most significant bits of the wire
 */
public func Msbs(w : Wire) : Wire {
    LsbAndMsbs(w)[1]
}
/**
 * Get the most significant bit (bit n-1) of a wire.
 * @param w The wire to get the msb from
 * @return The most significant bit of the wire
 */
public func Msb(w : Wire) : Wire {
    LsbsAndMsb(w)[1]
}
/**
 * Get the least significant bits (not bit n-1) of a wire.
 * @param w The wire to get the lsbs from
 * @return The leasts significant bits of the wire
 */
public func Lsbs(w : Wire) : Wire {
    LsbsAndMsb(w)[0]
}
/**
 * Split a wire so that its least significant bit is a separate wire
 * @param w The wire to split
 * @return A tuple (lsb, msbs)
 */
public func LsbAndMsbs(w : Wire) : (Wire, Wire) {
    let splits = Split(w, [1, w.GetWidth() - 1])
    (splits[0], splits[1])
}
/**
 * Split a wire so that its most significant bit is a separate wire
 * @param w The wire to split
 * @return A tuple (lsbs, msb)
 */
public func LsbsAndMsb(w : Wire) : (Wire, Wire) {
    let splits = Split(w, [w.GetWidth() - 1, 1])
    (splits[0], splits[1])
}
/**
 * Replicate a signal into a wire of a given width
 * @param a The input wire
 * @param w The number of times to replicate the signal
 * @return The replicated wire
 */
public func Replicate(a : Wire, w : Int64) : Wire {
    Combine(Array<Wire>(w, { i : Int64 => a }))
}