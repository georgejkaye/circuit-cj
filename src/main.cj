from circuits import graphs.*
from circuits import syntax.*

from std import collection.ArrayList

main(){

    let vs = ArrayList<Vertex>(3, {i : Int64 => Vertex()})
    
    let e1 = Edge(AND)

    e1.SetSource(0, vs[0])
    e1.SetSource(1, vs[0])
    e1.SetTarget(0, vs[1])

    let e2 = Edge(NOT)

    e2.SetSource(0, vs[1])
    e2.SetTarget(0, vs[2])

    let es = ArrayList<Edge>([e1,e2])

    let h = Hypergraph(vs,es)

    println(h)

    println(if (h.Typecheck()) { "yes!" } else { "no" })

    return 0
}