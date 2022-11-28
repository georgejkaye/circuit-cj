/**
 * graphs/vertex.cj
 *
 * @author George Kaye
 * @since 0.2
 */

package graphs

public enum VertexType {
    | SOURCE
    | TARGET
}
extend VertexType <: ToString {
    public func toString() : String {
        match(this) {
            case SOURCE => "source"
            case TARGET => "target"
        }
    }
}
/**
 * An EdgeConnection specifies an edge that a vertex
 * is a source or target of, and which index it is.
 */
public struct EdgeConnection<V, G> <: ToString & Equatable<EdgeConnection<V, G>> & Hashable
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    public EdgeConnection(
        public let edge : Edge<V, G>,
        public let index : Int64,
        public let vertexType : VertexType
    ) {}
    public func toString() : String {
        let initial = match(this.vertexType) {
            case SOURCE => "s"
            case TARGET => "t"
        }
        "${edge}.${initial}${index}"
    }
    public operator func ==(right: EdgeConnection<V, G>) : Bool {
        this.edge == right.edge && this.index == right.index
    }
    public operator func !=(right : EdgeConnection<V, G>) : Bool {
        !(this == right)
    }
    // HACK: This won't be unique if you have something with more than
    // 100000 sources or targets
    public func hashCode() : Int64 {
        let code = edge.GetId() * 100000 + index
        match(vertexType) {
            case SOURCE => code
            case TARGET => -code
        }
    }
    public func GetWidth() : Int64 {
        let t = match(vertexType) {
            case SOURCE => edge.GetSource(index)
            case TARGET => edge.GetTarget(index)
        }
        t.GetWidth()
    }
    public func GetEdge() : Edge<V, G> {
        this.edge
    }
    public func GetIndex() : Int64 {
        this.index
    }
}
public enum InterfaceType {
    | INPUT
    | OUTPUT
}
extend InterfaceType <: ToString & Hashable & Equatable<InterfaceType> {
    public func toString() : String {
        match(this) {
            case INPUT => "input"
            case OUTPUT => "output"
        }
    }
    public func hashCode() : Int64 {
        match(this) {
            case INPUT => 0
            case OUTPUT => 1
        }
    }
    public operator func ==(rhs : InterfaceType) : Bool {
        this.hashCode() == rhs.hashCode()
    }
    public operator func !=(rhs : InterfaceType) : Bool {
        !(this == rhs)
    }
}
public struct InterfaceElement<V, G> <: Hashable & ToString & Equatable<InterfaceElement<V, G>>
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    let id : Int64 = GetNextId()
    public InterfaceElement(
        public let graph : InterfacedHypergraph<V, G>,
        public let index : Int64,
        public let interfaceType : InterfaceType
    ){}
    public func hashCode() : Int64 {
        this.id
    }
    public func toString() : String {
        "${this.graph.GetName()} ${this.interfaceType}::${this.index}"
    }
    public operator func ==(rhs : InterfaceElement<V, G>) : Bool {
        this.graph == rhs.graph && this.index == rhs.index && this.interfaceType == rhs.interfaceType
    }
    public operator func !=(rhs : InterfaceElement<V, G>) : Bool {
        !(this == rhs)
    }
}
/**
 * A vertex is a wire in a circuit.
 * Vertices can be the source at most one edge, but the target of an
 * arbitrary number of edges, which represents forking wires.
 */
public class Vertex<V, G>
    <: Identifiable & Equatable<Vertex<V, G>> & Hashable & ToString & HasWidth & Socket
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    let width : Int64
    let id : Int64 = GetNextId()
    var inEdge : Option<EdgeConnection<V, G>> = None
    var outEdges : HashSet<EdgeConnection<V, G>> = HashSet<EdgeConnection<V, G>>()
    var feedback : Int64 = 0
    var owner : Hypergraph<V, G> = Hypergraph<V, G>()
    let interfacedInputs : HashSet<InterfaceElement<V, G>> = HashSet<InterfaceElement<V, G>>()
    let interfacedOutputs : HashSet<InterfaceElement<V, G>> = HashSet<InterfaceElement<V, G>>()
    public init(width: Int64){
        this.width = width
        this.owner.AddVertex(this)
    }
    public init() {
        this(1)
    }
    public func Clone() : Vertex<V, G> {
        Vertex(this.width)
    }
    public func GetId() : Int64 {
        this.id
    }
    public func GetWidth() : Int64 {
        this.width
    }
    public func GetInEdge() : Option<EdgeConnection<V, G>> {
        this.inEdge
    }
    public func GetOutEdges() : HashSet<EdgeConnection<V, G>> {
        this.outEdges
    }
    public func SetInEdge(e : Edge<V, G>, i : Int64) : Unit {
        SetInEdge(EdgeConnection(e, i, TARGET))
    }
    public func SetInEdge(ec : EdgeConnection<V, G>) : Unit {
        this.inEdge = ec
    }
    public func SetInEdge(ec : Option<EdgeConnection<V, G>>) : Unit {
        match(ec) {
            case None => ()
            case Some(e) => SetInEdge(e)
        }
    }
    public func SetOutEdges(ecs : HashSet<EdgeConnection<V, G>>) : Unit {
        this.outEdges = ecs
    }
    public func RemoveInEdge(es : HashSet<Edge<V, G>>) : Unit {
        for (e in es) {
            RemoveInEdge(e)
        }
    }
    public func RemoveInEdge() : Unit {
        this.inEdge = None
        this.PostAlterInEdge()
    }
    public func RemoveInEdge(e : Edge<V, G>) : Unit {
        match(this.inEdge) {
            case None => ()
            case Some(ec) =>
                if (ec.GetEdge() == e) {
                    this.inEdge = None
                    this.PostAlterInEdge()
                }
        }
    }
    func PostAlterInEdge() : Unit {
        // TODO?
    }
    func PostAlterOutEdges() : Unit {
        if(outEdges.size == 0){
            this.owner.AddVertexToRightmostTraversalElements(this)
        } else {
            this.owner.RemoveVertexFromRightmostTraversalElements(this)
        }
    }
    public func RemoveOutEdges(es : HashSet<Edge<V, G>>) : Unit {
        for(e in es) {
            this.RemoveOutEdge(e)
        }
        this.PostAlterOutEdges()
    }
    public func RemoveOutEdge(e : Edge<V, G>) : Unit {
        this.outEdges.removeIf({ec : EdgeConnection<V, G> => ec.GetEdge() == e})
        this.PostAlterOutEdges()
    }
    public func RemoveOutEdge(e : Edge<V, G>, i : Int64) : Unit {
        this.outEdges.removeIf({ec : EdgeConnection<V, G> => ec.GetEdge() == e && ec.GetIndex() == i})
        this.PostAlterOutEdges()
    }
    public func AddOutEdge(e : Edge<V, G>, i : Int64) : Unit {
        outEdges.put(EdgeConnection(e, i, SOURCE))
        this.PostAlterOutEdges()
    }
    public func AddAllOutEdges(es : HashSet<EdgeConnection<V, G>>) {
        for(ec in es) {
            this.AddOutEdge(ec.GetEdge(), ec.GetIndex())
        }
        this.PostAlterOutEdges()
    }
    func IncrementFeedback() : Unit {
        this.feedback++
    }
    func DecrementFeedback() : Unit {
        this.feedback--
    }
    public func toString() : String {
        "v${this.GetId()}"
    }
    public operator func ==(right: Vertex<V, G>) : Bool {
        this.GetId() == right.GetId()
    }
    public operator func !=(right : Vertex<V, G>) : Bool {
        this.GetId() != right.GetId()
    }
    public func GetOwner() : Hypergraph<V, G> {
        this.owner
    }
    public func SetOwner(f : Hypergraph<V, G>) : Unit {
        if(this.owner != f){
            this.owner.RemoveVertex(this)
            this.owner = f
        }
    }
    public func hashCode() : Int64 {
        this.id
    }
    public func GetName() : Option<String> {
        None
    }
    public func GetInterfacedInputs() : HashSet<InterfaceElement<V, G>> {
        this.interfacedInputs
    }
    public func SetAsInput(f : InterfacedHypergraph<V, G>, i : Int64) : Unit {
        this.interfacedInputs.put(InterfaceElement(f, i, INPUT))
    }
    public func RemoveAsInput(f : InterfacedHypergraph<V, G>) : Unit {
        this.interfacedInputs.removeIf({ ie => ie.graph == f})
    }
    public func RemoveAsInput(f : InterfacedHypergraph<V, G>, i : Int64) : Unit {
        this.interfacedInputs.removeIf({ ie => ie.graph == f && ie.index == i })
    }
    public func GetInterfacedOutputs() : HashSet<InterfaceElement<V, G>> {
        this.interfacedOutputs
    }
    public func SetAsOutput(f : InterfacedHypergraph<V, G>, i : Int64) : Unit {
        this.interfacedOutputs.put(InterfaceElement(f, i, OUTPUT))
    }
    public func RemoveAsOutput(f : InterfacedHypergraph<V, G>) : Unit {
        this.interfacedOutputs.removeIf({ ie => ie.graph == f})
    }
    public func RemoveAsOutput(f : InterfacedHypergraph<V, G>, i : Int64) : Unit {
        this.interfacedOutputs.removeIf({ ie => ie.graph == f && ie.index == i })
    }
}

public interface ContainsVertex<V, G>
    where V <: ValueSymbol, V <: Equatable<V>, G <: PrimitiveSymbol<V>, G <: Equatable<G>
{
    func GetVertex() : Vertex<V, G>
}
extend Vertex<V, G> <: ContainsVertex<V, G> {
    public func GetVertex() : Vertex<V, G> {
        this
    }
}