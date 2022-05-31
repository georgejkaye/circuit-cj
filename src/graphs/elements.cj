package graphs 

from std import collection.{ArrayList,HashMap}

import syntax.*

public class Vertex <: OwnedAtom<Hypergraph> {
    var inEdges : ArrayList<(Edge , UInt64)> = ArrayList()
    var outEdges : ArrayList<(Edge , UInt64)> = ArrayList()
    init(){
        super()
    }
    init(globalId : Option<Int64>){
        super(globalId)
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
    public override func toString() : String {
        "Vertex v${super.id} "
    }
}

public class Edge <: OwnedAtom<Hypergraph> {
    var sources : HashMap<UInt64, Vertex> = HashMap()
    var targets : HashMap<UInt64, Vertex> = HashMap()
    var label : Option<Label> = None 
    init(){
        super()
    }
    init(globalId : Option<Int64>){
        super(globalId)
    }
    func SetVertex(i : UInt64, newVertex : Vertex, map : HashMap<UInt64, Vertex>, exn : (Edge, UInt64, Vertex) -> Exception) : Unit {
        match (map.get(i)) {
            case Some(oldVertex) => throw exn(this, i, oldVertex)
            case None    => map.put(i, newVertex)
        }
    }
    func UnsafeSetVertex(i : UInt64, newVertex : Vertex, map : HashMap<UInt64, Vertex>) : Unit {
        map.put(i, newVertex)
    }
    func SetSource(i : UInt64, newVertex : Vertex) : Unit {
        SetVertex(i, newVertex, this.sources, {e, i, v => SourceAlreadyExistsException("SetSource", e, i, v)})
    }
    func UnsafeSetSource(i : UInt64, newVertex : Vertex) : Unit {
        UnsafeSetVertex(i, newVertex, sources)
    }
    func SetTarget(i : UInt64, newVertex : Vertex) : Unit {
        SetVertex(i, newVertex, this.targets, {e, i, v => TargetAlreadyExistsException("SetTarget", e, i, v)})
    }
    func UnsafeSetTarget(i : UInt64, newVertex : Vertex) : Unit {
        UnsafeSetVertex(i, newVertex, targets)
    }
    func RemoveVertex(i : UInt64, map : HashMap<UInt64, Vertex>) : Unit {
        map.remove(i)
    }
    func RemoveSource(i : UInt64) : Unit {
        RemoveVertex(i, sources)
    }
    func RemoveTarget(i : UInt64) : Unit {
        RemoveVertex(i, targets)
    }
    public override func toString() : String {
        "Edge e${super.id}"
    } 
}