package graphs

public func MergeVertices(v : Vertex, w : Vertex) : (Vertex, Vertex) {
    
    let wInEdges = w.GetInEdges()
    let wOutEdges = w.GetOutEdges() 
    
    v.AddAllInEdges(w.GetInEdges())
    v.AddAllOutEdges(w.GetOutEdges())

    for ((e, i) in wInEdges) {
        e.SetTarget(i, v)
    }
    for ((e, i) in wOutEdges) {
        e.SetSource(i, v)
    }

    match(w.GetOwner()) {
        case None => ()
        case Some(g) => g.RemoveVertex(w)
    }
    (v, w)
}

func CloneOrRetain(f : InterfacedHypergraph, clone : Bool) : (Hypergraph, Array<Vertex>, Array<Vertex>) {
    if(clone) {
        f.Clone()
    } else {
        (f.GetGraph(), f.GetInputVertices(), f.GetOutputVertices())
    }
}

func Seq(f : InterfacedHypergraph, g : InterfacedHypergraph, clone : Bool) : InterfacedHypergraph {
    if (f.GetOutputPorts() != g.GetInputPorts()){
        throw OutputInputMismatchException("Seq", f, g)
    }

    let (newF, newFInputs, newFOutputs) = CloneOrRetain(f, clone)
    let (newG, newGInputs, newGOutputs) = CloneOrRetain(g, clone)

    for (i in 0..f.GetOutputs()){
        MergeVertices(newFOutputs[i], newGInputs[i])
    }

    let fVertices = newF.GetVertices()
    let gVertices = newG.GetVertices()

    gVertices.removeAll(newGInputs)

    let newVertices = fVertices
    newVertices.putAll(gVertices)
    let newEdges = newF.GetEdges()
    newEdges.putAll(newG.GetEdges())

    let newGraph = Hypergraph(newVertices, newEdges)
    InterfacedHypergraph(
        newGraph, 
        Specification(
            "${f.GetName()} ⨟ ${g.GetName()}}",
            f.GetInputPorts(),
            g.GetOutputPorts()
        ),
        newFInputs, 
        newGOutputs
    )
}

public func Seq(f : InterfacedHypergraph, g : InterfacedHypergraph) : InterfacedHypergraph {
    Seq(f, g, true)
}

func Par(f : InterfacedHypergraph, g : InterfacedHypergraph, clone : Bool) : InterfacedHypergraph {

    let (newF, newFInputs, newFOutputs) = CloneOrRetain(f, clone)
    let (newG, newGInputs, newGOutputs) = CloneOrRetain(g, clone)

    let fVertices = newF.GetVertices()
    let gVertices = newG.GetVertices()

    let newVertices = fVertices
    newVertices.putAll(gVertices)
    let newEdges = newF.GetEdges()
    newEdges.putAll(newG.GetEdges())

    let newInputs = Array<Vertex>(f.GetInputs() + g.GetInputs()){
        i => if(i < newFInputs.size()) {
            newFInputs[i]
        } else {
            newGInputs[i - f.GetInputs()]
        }
    } 
    let newOutputs = Array<Vertex>(f.GetOutputs() + g.GetOutputs()){
        i => if(i < newFOutputs.size()) {
            newFOutputs[i]
        } else {
            newGOutputs[i - f.GetInputs()]
        }
    } 

    let newGraph = Hypergraph(newVertices, newEdges)

    func MakeParPorts(
        fArray : Array<Port>,
        gArray : Array<Port>
    ) : Array<Port> {
        Array<Port>(fArray.size() + fArray.size()){
            i : Int64 => if (i < fArray.size()) {
                fArray[i]
            } else {
                gArray[i - fArray.size()]
            }
    }
    }

    let newInputPorts = MakeParPorts(f.GetInputPorts(), g.GetInputPorts())
    let newOutputPorts = MakeParPorts(f.GetOutputPorts(), g.GetOutputPorts())
    
    InterfacedHypergraph(
        newGraph,
        Specification(
            "${f.GetName()} ⊗ ${g.GetName()}}",
            newInputPorts,
            newOutputPorts
        ),
        newInputs, 
        newOutputs
    )

}

public func Par(f : InterfacedHypergraph, g : InterfacedHypergraph) : InterfacedHypergraph {
    Par(f, g, true)
}