/**
 * rewrite.cj
 *
 * This file contains methods for rewriting hypergraphs.
 */

package hypergraphs

import debug.*

/**
 * Remove all parts of the graph that can be accessed by travelling left from a wire
 * Any dangling targets will be set to the inputs - the ordering is based on the
 * order of the edges in the list and then the order of the sources of the edges
 * This method should only be used as an intermediate step, the result is not well-defined
 * @param f The hypergraph
 * @param w The wire
 * @return A clone of the hypergraph with all parts of the hypergraph left of a given source vertex removed
 */
func RemoveLeft(f : Hypergraph, w : Wire){
    RemoveLeft(f, f.GetWireVertex(w))
}

/**
 * Remove all parts of the graph that can be accessed by travelling left from a source vertex
 * @param f The hypergraph
 * @param s The source vertex
 * @return A clone of the hypergraph with all parts of the hypergraph left of a given source vertex removed
 */
func RemoveLeft(f : Hypergraph, s : Source){
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
                removedTargets.add(t)
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
        for(v in e.sources){
            let t = f.GetConnL(v)
            if(includes(removedTargets, t)){
                newInputs.add(t)
            }
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
    f.Disjoint(h) ? h : h.Clone()
}

/**
 * Inject a hypergraph g into a hypergraph f (g >> f)
 * For all inputs of g, find a corresponding wire in f and 
 * For example, for f and g defined as follows:
 *    
 *     |F| -- *(a) -- |F'|            |in| -- *(a) -- |G|
 *
 *  g >> f will result in the following hypergraph
 *
 *                                   ---- |F'|
 *              |F| -- *(a) -- |fork| 
 *                                   ---- |G|
 *
 * If any of the input wires of g does not exist in f, then throws an exception
 *
 * @param f The hypergraph to be injected into
 * @param g The hypergraph to be injected
 * @return A clone of hypergraph f with a clone of g injected into it
 */
func Inject(f : Hypergraph, g : Hypergraph, name!: Option<String>){
    let f = f
    let g = f.Disjoint(g) ? g : g.Clone()
    // We will preserve all the inputs of f, but some of the inputs of g will be injected in
    let newInputs = ArrayList<Target>(f.GetInputs())
    let newEdges = ArrayList<Edge>(f.GetEdges())
    let newConns = MapBuilder<Target,Source>()
    for(t in g.GetInputs()){
        var assigned = false
        let s = g.GetConnR(t)
        for(w in s.wires){
            // Different buses may be assigned, as long as one matches we're fine
            let vf = f.GetWireVertexOption(w)
            let b = match(vf){
                case $None   => { false }
                case Some(v) => {
                    // Create the new targets of the fork
                    let t1 = Target()
                    let t2 = Target()
                    // Create the new fork edge with the existing source
                    let fork = Edge(FORK, [v], [t1,t2])
                    newEdges.add(fork)
                    // Create the source for the edge in f
                    let s1 = Source()
                    match(f.GetEdge(v)){
                        case EdgePort(e,i) => e.sources.set(i, s1)
                        case InterfacePort(i) => f.GetOutputs().set(i, s1)
                    }
                    newConns.add(t1,s1)
                    // Create the source for the edge in g
                    let s2 = Source()
                    let vg = g.GetWireVertex(w)
                    match(g.GetEdge(vg)){
                        case EdgePort(e,i) => e.sources.set(i, s2)
                        case InterfacePort(i) => g.GetOutputs().set(i, s2)
                    }
                    newConns.add(t2,s2)
                    true
                }
            }
            // Dually, duplicate buses may be shared, so once we have one we can stop
            if(b) { 
                assigned = true
                break 
            }
        }
        if(!assigned){
            newInputs.add(t)
        }
    }
    newEdges.addAll(g.GetEdges())

    // The outputs of both graphs are preserved
    let newOutputs = ArrayList<Source>(f.GetOutputs())
    newOutputs.addAll(g.GetOutputs())
    // Set up the connections
    for(t in f.GetTargets()){
        newConns.add(t, f.GetConnR(t))
    }
    for(t in g.GetTargets()){
        newConns.add(t, g.GetConnR(t))
    }
    // Return the newly injected hypergraph
    Hypergraph(name, newEdges, newInputs, newOutputs, newConns.toMap())
}

/**
 * Fork some given source vertices and send the new copy to the outputs.
 * Original outputs are stubbed.
 * Order of the new outputs is determined by the order of the given list
 * @param f  The hypergraph to extract the vertices from
 * @param vs The list of source vertices to extract
 * @return The hypergraph with the source vertices extracted
 */
func Extract(f : Hypergraph, vs : ArrayList<Source>) : Hypergraph {
    Debug("Extract", "Extracting vertices ${SourceListToString(vs)} from '${f.GetName()}'")
    let newEdges = ArrayList<Edge>(f.GetEdges())
    let newOutputs = ArrayList<Source>()
    let newConns = MapBuilder<Target, Source>()
    for(s in vs){
        let s2 = match(f.GetEdge(s)){
            case EdgePort(e, i) => {
                let t1 = Target()
                let t2 = Target()
                let fork = Edge(FORK, [s], [t1,t2])
                newEdges.add(fork)
                let s1 = Source()
                let s2 = Source()
                newConns.add(t1,s1)
                newConns.add(t2,s2)
                e.sources.set(i,s1)
                s2
            }
            case InterfacePort(i) => {
                s
            }
        }
        newOutputs.add(s2)
    }
    for(t in f.GetTargets()){
        newConns.add(t, f.GetConnR(t))
    }
    for(s in f.GetOutputs()){
        if(!includes(newOutputs, s)){
            let stub = Edge(STUB, [s], [])
            newEdges.add(stub)
        }
    }
    Hypergraph(newEdges, f.GetInputs(), newOutputs, newConns.toMap())
}