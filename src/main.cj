from circuits import graphs.*
from circuits import syntax.*

from std import collection.ArrayList
from std import collection.HashSet

main(){

    let v1 = Vertex()
    let v2 = Vertex()
    let v3 = Vertex()

    let vs = HashSet<Vertex>([v1,v2,v3])
    
    let e1 = Edge(AND)

    e1.SetSource(0, v1)
    e1.SetSource(1, v1)
    e1.SetTarget(0, v2)

    let e2 = Edge(NOT)

    e2.SetSource(0, v2)
    e2.SetTarget(0, v3)

    let es = HashSet<Edge>([e1,e2])

    let inputs = ArrayList<Vertex>([v1])
    let outputs = ArrayList<Vertex>([v3])

    let h = Hypergraph(vs,es,inputs,outputs)

    println(h)

    let check = h.WellFormednessCheck()

    println("${check}")

    return 0
}