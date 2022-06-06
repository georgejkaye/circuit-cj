package graphs

public class Hypergraph <: ToString {
    let vertices : ArrayList<Vertex>
    let edges : ArrayList<Edge>

    public init (vertices : ArrayList<Vertex>, edges : ArrayList<Edge>){
        this.vertices = vertices
        this.edges = edges
        for (v in this.vertices) {
            v.SetOwner(this)
        }
        for (e in this.edges) {
            e.SetOwner(this)
        }
    }

    public func Typecheck() : Bool {
        for (e in this.edges) {
            if (!e.Typecheck()){
                return false
            }
        }
        true
    }

    public func toString() : String {
        let vertexString = this.vertices.toString()
        let edgeString = this.edges.toString()
        "V = ${vertexString}  E = ${edgeString}"
    }

}