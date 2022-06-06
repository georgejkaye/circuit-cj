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
    public func GetOwner() {
        this.owner
    }
    public func SetOwner(h : Hypergraph) {
        this.owner = Some(h)
    }
    public func RemoveOwner() {
        this.owner = Option<Hypergraph>.None
    }
}

public class Vertex <: ToString & Identifiable & Equatable<Vertex> & Ownable<Hypergraph> {
    let element : Element
    var inEdges : ArrayList<(Edge , UInt64)> = ArrayList()
    var outEdges : ArrayList<(Edge , UInt64)> = ArrayList()
    public init(globalId: Option<Identifier>, owner: Option<Hypergraph>){
        this.element = Element(globalId, owner)            
    
    }
    public init() {
        this(Option<Identifier>.None, Option<Hypergraph>.None)
    }
    func AddInEdge(e : Edge, i : UInt64) : Unit {
        inEdges.add((e, i))
    }
    func AddOutEdge(e : Edge, i : UInt64) : Unit {
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
    func RemoveInEdge(edge : Edge, i : UInt64) : Unit {
        inEdges.removeIf({e => e == (edge, i)})
    }
    func RemoveOutEdge(edge : Edge, i : UInt64) : Unit {
        outEdges.removeIf({e => e == (edge, i)})
    }
    public func toString() : String {
        "v${this.element.GetId()}"
    }
    public func GetId() : Int64 {
        this.element.GetId()
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
}

public class Edge <: ToString & Identifiable & Equatable<Edge> {
    let element : Element
    let label : Label
    var sources : HashMap<UInt64, Vertex> = HashMap()
    var targets : HashMap<UInt64, Vertex> = HashMap()
    public init(globalId : Option<Identifier>, owner: Option<Hypergraph>, label : Label) {
        this.element = Element(globalId, owner)
        this.label = label
    }
    public init(label : Label) {
        this(Option<Identifier>.None, Option<Hypergraph>.None, label)
    }
    public func GetLabel() : Label {
        this.label
    }
    public func SetVertex(i : UInt64, newVertex : Vertex, map : HashMap<UInt64, Vertex>, exn : (Edge, UInt64, Vertex) -> Exception) : Unit {
        match (map.get(i)) {
            case Some(oldVertex) => throw exn(this, i, oldVertex)
            case None    => map.put(i, newVertex)
        }
    }
    public func UnsafeSetVertex(i : UInt64, newVertex : Vertex, map : HashMap<UInt64, Vertex>) : Unit {
        map.put(i, newVertex)
    }
    public func SetSource(i : UInt64, newVertex : Vertex) : Unit {
        SetVertex(i, newVertex, this.sources, {e, i, v => SourceAlreadyExistsException("SetSource", e, i, v)})
    }
    public func UnsafeSetSource(i : UInt64, newVertex : Vertex) : Unit {
        UnsafeSetVertex(i, newVertex, sources)
    }
    public func SetTarget(i : UInt64, newVertex : Vertex) : Unit {
        SetVertex(i, newVertex, this.targets, {e, i, v => TargetAlreadyExistsException("SetTarget", e, i, v)})
    }
    public func UnsafeSetTarget(i : UInt64, newVertex : Vertex) : Unit {
        UnsafeSetVertex(i, newVertex, targets)
    }
    public func RemoveVertex(i : UInt64, map : HashMap<UInt64, Vertex>) : Unit {
        map.remove(i)
    }
    public func RemoveSource(i : UInt64) : Unit {
        RemoveVertex(i, sources)
    }
    public func RemoveTarget(i : UInt64) : Unit {
        RemoveVertex(i, targets)
    }
    public func toString() : String {
        "e${this.element.GetId()}"
    }
    public func GetId() : Int64 {
        this.element.GetId()
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
}