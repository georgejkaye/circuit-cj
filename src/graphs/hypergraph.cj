package graphs

from std import collection.HashSet
from std import collection.ArrayList

public enum WellformednessStatus {
    | Okay
    | InputNotInGraph(Vertex)
    | OutputNotInGraph(Vertex)
    | SourceNotAssigned(Edge, Int64)
    | TargetNotAssigned(Edge, Int64)
    | SourceNotInGraph(Edge, Int64, Vertex)
    | TargetNotInGraph(Edge, Int64, Vertex)
    | IncorrectDomain(Edge)
    | IncorrectCodomain(Edge)
}

public class Hypergraph <: Identifiable & ToString & InputOutput & Nameable{
    
    let uniqueId : Identifier = Identifier()
    let vertices : HashSet<Vertex>
    let edges : HashSet<Edge>
    let inputs : ArrayList<Vertex>
    let outputs : ArrayList<Vertex>

    public init (vertices : HashSet<Vertex>, edges : HashSet<Edge>, inputs: ArrayList<Vertex>, outputs: ArrayList<Vertex>){
        this.vertices = vertices
        this.edges = edges
        this.inputs = inputs
        this.outputs = outputs

        for (v in this.vertices) {
            v.SetOwner(this)
        }
        for (e in this.edges) {
            e.SetOwner(this)
        }
        if (!vertices.containsAll(inputs)) {
            throw InputsNotInHypergraphException("Hypergraph", this)
        }
        if (!vertices.containsAll(outputs)) {
            throw OutputsNotInHypergraphException("Hypergraph", this)
        }
    }

    public func WellformednessCheck() : WellformednessStatus {

        func EdgeVertexCheck(
            e : Edge,
            array : Array<Option<Vertex>>,
            notAssigned : (Edge, Int64) -> WellformednessStatus, 
            notPresent : (Edge, Int64, Vertex) -> WellformednessStatus
        ) : WellformednessStatus {
            for (i in 0..array.size()) {
                let vOpt : Option<Vertex> = array[i]
                let status : WellformednessStatus = match(vOpt) {
                    case None    => notAssigned(e, i)
                    case Some(v) => Okay
                        if (!this.vertices.contains(v)) {
                            notPresent(e, i, v)
                        } else {
                            Okay
                        }
                }
                match (status) {
                    case Okay => ()
                    case v => return v
                }
            }
            Okay
        }


        for (e in this.edges) {
            let sourceCheck = EdgeVertexCheck(
                e, 
                e.GetSources(), 
                { e, i => SourceNotAssigned(e,i) }, 
                { e, i, v => SourceNotInGraph(e,i,v)}
            )
            match(sourceCheck) {
                case Okay => ()
                case v => return v
            }
            let targetCheck = EdgeVertexCheck(
                e, 
                e.GetTargets(), 
                { e, i => TargetNotAssigned(e,i) },
                { e, i, v => TargetNotInGraph(e,i,v) }
            )
            match(targetCheck) {
                case Okay => ()
                case v => return v
            }
            
        }
        Okay
    }
    public func toString() : String {
        let vertexString = this.vertices.toString()
        let edgeString = this.edges.toString()
        let inputString = this.inputs.toString()
        let outputString = this.outputs.toString()
        "V = ${vertexString}  E = ${edgeString}  in = ${inputString}  out = ${outputString}"
    }
    public func GetId() : Int64 {
        this.uniqueId.GetId()
    }
    public func GetName() : String {
        "hg${this.uniqueId.GetId()}"
    }
    public func GetInputs() : Int64 {
        this.inputs.size()
    }
    public func GetOutputs() : Int64 {
        this.outputs.size()
    }

}