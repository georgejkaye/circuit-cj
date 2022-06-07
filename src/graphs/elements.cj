package graphs 

from std import collection.{ArrayList,HashMap}

import syntax.*

public interface Ownable<T> {
    func GetOwner() : Option<T> 
    func SetOwner(t : T) : Unit
    func RemoveOwner() : Unit
}

public class Element <: Identifiable & Ownable<Hypergraph> {
    let atom : Atom
    var owner : Option<Hypergraph> = None
    public init(globalId: Option<Identifier>, owner : Option<Hypergraph>) {
        this.atom = Atom(globalId)
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
    public func SetOwner(h : Hypergraph) {
        match (this.owner) {
            case None => this.owner = Some(h)
            case Some(o) => throw AlreadyOwnedException("SetOwner", this, o, h)
        }
        this.owner = Some(h)
    }
    public func RemoveOwner() {
        this.owner = Option<Hypergraph>.None
    }
}

public class Vertex <: ToString & Identifiable & Equatable<Vertex> & Ownable<Hypergraph> & Hashable {
    let element : Element
    var inEdges : ArrayList<(Edge , Int64)> = ArrayList()
    var outEdges : ArrayList<(Edge , Int64)> = ArrayList()
    var feedback : Int64 = 0
    public init(globalId: Option<Identifier>, owner: Option<Hypergraph>){
        this.element = Element(globalId, owner)            
    
    }
    public init() {
        this(Option<Identifier>.None, Option<Hypergraph>.None)
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
        "v${this.element.GetId()}"
    }
    public func GetId() : Int64 {
        this.element.GetId()
    }
    public func GetGlobalId() : Int64 {
        this.element.GetGlobalId()
    }
    public operator func ==(right: Vertex) : Bool {
        this.GetId() == right.GetId()
    }
    public operator func !=(right : Vertex) : Bool {
        this.GetId() != right.GetId()
    }
    public func GetOwner() : Option<Hypergraph> {
        this.element.GetOwner()
    }
    public func SetOwner(owner : Hypergraph) : Unit {
        this.element.SetOwner(owner)
    }
    public func RemoveOwner() : Unit {
        this.element.RemoveOwner()
    }
    public func hashCode() : Int64 {
        this.element.GetId()
    }
}

public class Edge <: ToString & Identifiable & Equatable<Edge> & Ownable<Hypergraph> & Hashable {
    let element : Element
    let label : Label
    let sources : Array<Option<Vertex>>
    let targets : Array<Option<Vertex>>
    public init(globalId : Option<Identifier>, owner: Option<Hypergraph>, label : Label) {
        this.element = Element(globalId, owner)
        this.label = label
        this.sources = Array<Option<Vertex>>(label.GetInputs()){ i => Option<Vertex>.None }
        this.targets = Array<Option<Vertex>>(label.GetOutputs()){ i => Option<Vertex>.None }
    }
    public init(label : Label) {
        this(Option<Identifier>.None, Option<Hypergraph>.None, label)
    }
    public func GetLabel() : Label {
        this.label
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
        "e${this.element.GetId()}"
    }
    public func GetId() : Int64 {
        this.element.GetId()
    }
    public func GetGlobalId() : Int64 {
        this.element.GetGlobalId()
    }
    public operator func ==(right: Edge) : Bool {
        this.GetId() == right.GetId()
    }
    public operator func !=(right : Edge) : Bool {
        this.GetId() != right.GetId()
    } 
    public func GetOwner() : Option<Hypergraph> {
        this.element.GetOwner()
    }
    public func SetOwner(owner : Hypergraph) : Unit {
        this.element.SetOwner(owner)
    }
    public func RemoveOwner() : Unit {
        this.element.RemoveOwner()
    }
    public func hashCode() : Int64 {
        this.element.GetId()
    }
}