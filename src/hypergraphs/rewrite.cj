package hypergraphs

/**
 * Remove all parts of the graph that can be accessed by travelling left from a source vertex
 * @param s The source vertex
 * @return A clone of the hypergraph with all parts of the hypergraph left of a given source vertex removed
 */
external func RemoveLeft(f : Hypergraph, s : Source){
    let frontier = ArrayList<Source>([s])
    let explored = ArrayList<Edge>()
    let removedInputs = ArrayList<Int64>()
    let removedTargets = ArrayList<Target>()
    // Traverse the graph
    while(frontier.size() != 0){
        let s = frontier.removeAt(0)
        let t = f.GetConnL(s)
        match(f.GetEdge(t)){
            case EdgePort(e, i) => {
                explored.add(e)
                frontier.addAll(e.sources)
                removedTargets.addAll(e.targets)
            }
            case InterfacePort(i) => {
                removedInputs.add(i)
            }
        }
    }
    // Only include edges not found by the search
    let newEdges = ArrayList<Edge>()
    for(e in f.GetEdges()){
        if(!includes(explored, e)){
            newEdges.add(e)
        }
    }
    // Only include vertices not found by the search
    let oldInputs = f.GetInputs()
    let newInputs = ArrayList<Target>()
    for(i in 0..oldInputs.size()){
        if(!includes(removedInputs, i)){
            newInputs.add(oldInputs[i])
        }
    }
    // If there are any dangling sources, add their targets to the inputs
    for(e in newEdges){
        let t = f.GetConnL(s)
        if(includes(removedTargets, t)){
            newInputs.add(t)
        }
    }
    // If there are any dangling outputs, add their targets to the inputs
    for(v in f.GetOutputs()){
        let t = f.GetConnL(v)
        if(includes(removedTargets, t)){
            newInputs.add(t)
        }
    }
    // Outputs are unchanged
    let newOutputs = ArrayList<Source>(f.GetOutputs())
    // Build the new connections map
    let connsMap = MapBuilder<Target, Source>()
    for(v in newInputs){
        connsMap.add(v, f.GetConnR(v))
    }
    for(e in newEdges){
        for(v in e.targets){
            connsMap.add(v, f.GetConnR(v))
        }
    }
    // Make the new hypergraph
    let h = Hypergraph(newEdges, newInputs, newOutputs, connsMap.toMap())
    // Clone it in case this graph interacts with the original
    h.Clone()
}

func Inject(f : Hypergraph, g : Hypergraph){
    let f = f.Clone()
    for(t in g.GetInputs()){
        let s = g.GetConnR(t)
        for(w in s.wires){
            match(w.bus.name){
                case $None      => {}   
                case Some(text) => {
                    //let 
                    //let fork = Edge(FORK, )


                }
            }
        }
    }


}