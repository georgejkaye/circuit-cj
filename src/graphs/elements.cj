package graphs 

from std import collection.{ArrayList,HashMap}

import syntax.*

public interface Ownable<T> {
    func GetOwner() : Option<T> 
    func SetOwner(t : T) : Unit
    func RemoveOwner() : Unit
}

public abstract class Element <: Identifiable & Ownable<Hypergraph> & ToString & Hashable {
    let atom : Atom
    var owner : Option<Hypergraph> = None
    public init(owner : Option<Hypergraph>) {
        this.atom = Atom(Option<Identifier>.None)
        this.owner = owner
    }
    public func GetId() : Int64 {
        this.atom.GetId()
    }
    public func GetGlobalId() : Int64 {
        this.atom.GetGlobalId()
    }
    public func GetOwner() {
        this.owner
    }
    public open func SetOwner(h : Hypergraph) {
        match (this.owner) {
            case None => this.owner = Some(h)
            case Some(o) => throw AlreadyOwnedException("SetOwner", this, o, h)
        }
        this.owner = Some(h)
    }
    public open func RemoveOwner() {
        this.owner = Option<Hypergraph>.None
    }
    public func RemoveAndSetOwner(f : Hypergraph) {
        RemoveOwner()
        SetOwner(f)
    }
    public func hashCode() : Int64 {
        this.GetId()
    }
}

public class Vertex <: Element & Equatable<Vertex> {
    let width : Int64
    var inEdges : ArrayList<(Edge , Int64)> = ArrayList()
    var outEdges : ArrayList<(Edge , Int64)> = ArrayList()
    var feedback : Int64 = 0
    public init(width: Int64, owner: Option<Hypergraph>){
        super(owner)            
        this.width = width
    }
    public init(width: Int64) {
        this(width, Option<Hypergraph>.None)
    }
    public init() {
        this(1)
    }
    func GetWidth() : Int64 {
        this.width
    }
    func GetInEdges() : ArrayList<(Edge, Int64)> {
        this.inEdges
    }
    func GetOutEdges() : ArrayList<(Edge, Int64)> {
        this.outEdges
    }
    func AddInEdge(e : Edge, i : Int64) : Unit {
        inEdges.add((e, i))
    }
    func AddOutEdge(e : Edge, i : Int64) : Unit {
        outEdges.add((e, i))
    }
    func RemoveAllInEdge(edge : Edge) : Unit {
        inEdges.removeIf({e => e[0] == edge})
    }
    func RemoveAllOutEdge(edge : Edge) : Unit {
        outEdges.removeIf({e => e[0] == edge})
    }
    func RemoveAllEdge(edge : Edge) : Unit {
        RemoveAllInEdge(edge)
        RemoveAllOutEdge(edge)
    }
    func RemoveInEdge(edge : Edge, i : Int64) : Unit {
        inEdges.removeIf({e => e == (edge, i)})
    }
    func RemoveOutEdge(edge : Edge, i : Int64) : Unit {
        outEdges.removeIf({e => e == (edge, i)})
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
    public operator func ==(right: Vertex) : Bool {
        this.GetId() == right.GetId()
    }
    public operator func !=(right : Vertex) : Bool {
        this.GetId() != right.GetId()
    }
}

public class Edge <: Element & Equatable<Edge> {
    let label : Label
    let sources : Array<Option<Vertex>>
    let targets : Array<Option<Vertex>>
    public init(label: Label, sources : Array<Option<Vertex>>, targets : Array<Option<Vertex>>){
        super(Option<Hypergraph>.None)
        this.label = label
        this.sources = sources
        this.targets = targets
    }
    public init(label: Label, sources : Array<Vertex>, targets : Array<Vertex>){
        super(Option<Hypergraph>.None)
        this.label = label
        this.sources = map({ v : Vertex => Some(v) }, sources)
        this.targets = map({ v : Vertex => Some(v) }, targets)
    }
    public init(owner: Option<Hypergraph>, label : Label) {
        super(owner)
        this.label = label
        this.sources = Array<Option<Vertex>>(label.GetInputs()){ i => Option<Vertex>.None }
        this.targets = Array<Option<Vertex>>(label.GetOutputs()){ i => Option<Vertex>.None }
    }
    public init(label : Label) {
        this(Option<Hypergraph>.None, label)
    }
    public func GetLabel() : Label {
        this.label
    }
    public func ForEachSourceAndTarget(f : (Vertex) -> Unit) : Unit {
        func ForEachVertex(array : Array<Option<Vertex>>, f : (Vertex) -> Unit) : Unit {
            for (opt in array) {
                match (opt) {
                    case Some(v) => f(v)
                    case None => ()
                }
            }
        }
        ForEachVertex(this.sources, f)
        ForEachVertex(this.targets, f)
    }
    public override func SetOwner(f : Hypergraph) : Unit {
        match(this.owner) {
            case Some(o) => super.SetOwner(f)
            case None => 
                this.owner = f
                ForEachSourceAndTarget({ v => v.SetOwner(f)} )
        }
    }
    public override func RemoveOwner() : Unit {
        this.owner = Option<Hypergraph>.None
        ForEachSourceAndTarget({ v => v.RemoveOwner() })
    }
    func SetVertex(
        i : Int64, 
        newVertex : Vertex, 
        array : Array<Option<Vertex>>, 
        exn : (Edge, Int64, Vertex) -> Exception,
        vertexFn : (Vertex) -> Unit
    ) : Unit {
        match (array[i]) {
            case Some(oldVertex) => throw exn(this, i, oldVertex)
            case None    => 
                array[i] = newVertex
                vertexFn(newVertex)
        }
    }
    func RemoveVertex(i : Int64, array : Array<Option<Vertex>>) : Unit {
        array[i] = Option<Vertex>.None
    }
    public func SetSource(i : Int64, newVertex : Vertex) : Unit {
        SetVertex(
            i,
            newVertex,
            this.sources,
            {e, i, v => SourceAlreadyExistsException("SetSource", e, i, v)},
            { v => v.AddOutEdge(this, i) }
        )
    }
    public func GetSource(i : Int64) : Option<Vertex> {
        this.sources[i]
    }
    public func GetSources() : Array<Option<Vertex>> {
        this.sources
    }
    public func RemoveSource(i : Int64) : Unit {
        RemoveVertex(i, sources)
    }
    public func RemoveAndSetSource(i : Int64, newVertex : Vertex) : Unit {
        RemoveSource(i)
        SetSource(i, newVertex)
    }

    public func SetTarget(i : Int64, newVertex : Vertex) : Unit {
        SetVertex(
            i,
            newVertex,
            this.targets,
            {e, i, v => TargetAlreadyExistsException("SetTarget", e, i, v)},
            {v => v.AddInEdge(this, i)}
        )
    }
    public func GetTarget(i : Int64) : Option<Vertex> {
        this.targets[i]
    }
    public func GetTargets() : Array<Option<Vertex>> {
        this.targets
    }
    public func RemoveTarget(i : Int64) : Unit {
        RemoveVertex(i, targets)
    }
    public func RemoveAndSetTarget(i : Int64, newVertex : Vertex) : Unit {
        RemoveTarget(i)
        SetTarget(i, newVertex)
    }
    public func toString() : String {
        "e${this.GetId()}"
    }
    public operator func ==(right: Edge) : Bool {
        this.GetId() == right.GetId()
    }
    public operator func !=(right : Edge) : Bool {
        this.GetId() != right.GetId()
    }
}