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

    let f = Hypergraph(vs,es,inputs,outputs)

    println(f)

    let v4 = Vertex()
    let v5 = Vertex()

    let e3 = Edge(NOT)

    e3.SetSource(0, v4)
    e3.SetTarget(0, v5)

    let g = Hypergraph(
        HashSet<Vertex>([v4,v5]),
        HashSet<Edge>([e3]),
        ArrayList<Vertex>([v4]),
        ArrayList<Vertex>([v5])
    )

    println(g)

    let h = Par(f,g)

    println(h)

    return 0
}