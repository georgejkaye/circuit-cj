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

// /**
//  * For a list of created forks, remove those that have a stub as one argument
//  * @param fs The list of forks
//  * @param edges The list of all edges
//  * @param conns The map of connections
//  * @return The updated edges map and conns map
//  */
// func ReduceForkCounit(fs : ArrayList<Edge>, edges : ArrayList<Edge>, conns : MapBuilder<Target, Source>){
//     for(fork in fs) {

//     }
// }

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
    let f = f.Clone()
    let g = g.Clone()
    // We will preserve all the inputs of f, but some of the inputs of g will be injected in
    let newInputs = ArrayList<Target>(f.GetInputs())
    let newEdges = ArrayList<Edge>(f.GetEdges())
    let newConns = MapBuilder<Target,Source>()
    let createdForks = ArrayList<Edge>()
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
                    createdForks.add(fork)
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
                }
                true
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
 * WARNING: Modifies the original hypergraph
 * @param f  The hypergraph to extract the vertices from
 * @param vs The list of source vertices to extract
 * @return The hypergraph with the source vertices extracted
 */
func Extract(f : Hypergraph, buses : ArrayList<String>, name!: String = "") : Hypergraph {
    Debug("Extract", "Extracting buses ${PrintList(buses)} from '${f.GetName()}'")
    
    // Clone the hypergraph first so we don't modify the old one my mistake
    let newF = f.Clone()
    print("${newF}\n")
    // Find the vertices that correspond to the buses
    var vs = ArrayList<Source>()
    for(bus in buses){
        vs = newF.GetBusVertexList(bus, vs)
    }
    // Set up structures to track the new atoms
    let newEdges = ArrayList<Edge>(newF.GetEdges())
    let newOutputs = ArrayList<Source>()
    let newConns = MapBuilder<Target, Source>()
    let doneMap = MapBuilder<Source, Edge>()
    // For each vertex, fork it and set the copy to be one of the outputs
    for(s in vs){
        // Create a new fork edge
        let t1 = Target()
        let t2 = Target()
        let fork = Edge(FORK, [s], [t1,t2])
        newEdges.add(fork)
        // Create a source for the original edge
        let s1 = Source()
        // Create a source for the outputs
        let s2 = Source()
        // Join up the new sources and targets
        newConns.add(t1,s1)
        newConns.add(t2,s2)
        // If we have already forked this wire, we need to set the sources
        // of the new fork we created rather than those of the original edge
        let out = match(doneMap.toMap().get(s)){
            case Some(e) => {
                e.sources.set(0, s1)
                s2
            }
            case $None => {
                match(newF.GetEdge(s)){
                    case EdgePort(e, i) => {
                        e.sources.set(i,s1)
                        s2
                    }
                    case InterfacePort(i) => {
                        let stub = Edge(STUB, [s1], [])
                        newEdges.add(stub)
                        s2
                    }
                }
            }
        }
        doneMap.add(s, fork)
        newOutputs.add(out)
    }
    // Add the remaining connections from the original hypergraph
    for(t in newF.GetTargets()){
        newConns.add(t, newF.GetConnR(t))
    }
    let x = Hypergraph(name, newEdges, newF.GetInputs(), newOutputs, newConns.toMap())
    print("${x}\n")
    x
}

external func ResolveLinks(f : Hypergraph, name!: String = ""){
    let newF = f.Clone()
    let outputs = newF.GetOutputs()
    let edges = newF.GetEdges()
    let inlinks = MapBuilder<LinkSpec, ArrayList<Edge>>()
    let outlinks = MapBuilder<LinkSpec, ArrayList<Edge>>()
    // TODO remove once convinved that for((x, y) in map) works
    let inList = ArrayList<Edge>()
    let outList = ArrayList<Edge>()
    for(edge in edges){
        match(edge.generator){
            case INLINK(spec)  => {
                inList.add(edge)
                match(inlinks.toMap().get(spec)){
                    case Some(es) => {
                        es.add(edge)
                        true
                    } 
                    case $None    => {
                        let es = ArrayList<Edge>([edge])
                        inlinks.add(spec, es)
                        false
                    }
                }
                true
            }
            case OUTLINK(spec) => {
                outList.add(edge)
                match(outlinks.toMap().get(spec)){
                    case Some(es) => {
                        es.add(edge)
                        true
                    }
                    case $None    => {
                        let es = ArrayList<Edge>([edge])
                        outlinks.add(spec, es)
                        false
                    }
                }
                true
            }
            case _ => false
        }
    }
    Info("ResolveLinks", "Found the links")
    let linkConns = MapBuilder<Target, Source>()
    for((spec, outLinkEdges) in outlinks.toMap()){
        match(inlinks.toMap().get(spec)){
            case Some(inLinkEdges) => {
                let outs = outLinkEdges.size()
                let ins = inLinkEdges.size()
                // Deal with each port of the link in turn
                for(port in 0..spec.width){
                    var currentSource = outLinkEdges[0].sources[port]
                    // We need to join together multiple out links with the same spec
                    if(outs > 1){
                        for(j in 1..outs){
                            let nextSource = outLinkEdges[j].sources[port]
                            let t1 = Target()
                            let join = Edge(JOIN, [currentSource, nextSource], [t1])
                            edges.add(join)
                            let s1 = Source()
                            linkConns.add(t1,s1)
                            currentSource = s1
                        }
                    }

                    let idTarget : Target
                    // We need to fork to serve multiple in links with the same spec
                    if(ins > 1){
                        var currentTarget = Target()
                        idTarget = currentTarget
                        for(j in 2..ins){
                            let forkSource = Source()
                            linkConns.add(currentTarget, forkSource)
                            currentTarget = Target()
                            let fork = Edge(FORK, [forkSource], [currentTarget, inLinkEdges[ins-j+1].targets[port]])
                            edges.add(fork)
                        }
                        let forkSource = Source()
                        linkConns.add(currentTarget, forkSource)
                        let fork = Edge(FORK, [forkSource], [inLinkEdges[0].targets[port], inLinkEdges[1].targets[port]])
                        edges.add(fork)
                    } else {
                        idTarget = inLinkEdges[0].targets[port]
                    }
                    // In between the links we put an identity edge to preseve closed loops
                    let idEdge = Edge(IDENTITY,[currentSource],[idTarget])
                    edges.add(idEdge)

                }
                edges.removeIf({e : Edge => includes(inLinkEdges, e)})
            }
            case $None => {
                for(e in outLinkEdges){
                    let stubs = ArrayList<Edge>(spec.width, {i : Int64 => Edge(STUB, [e.sources[i]], []) })
                    edges.addAll(stubs)
                }
            }
        }
        edges.removeIf({e : Edge => includes(outLinkEdges, e)})
    }
    let deadInlinks = ArrayList<Edge>()
    let newEdges = ArrayList<Edge>()
    for(e in edges){
        match(e.generator){
            case INLINK(spec) => {
                for(i in 0..spec.width){
                    let bot = Edge(VALUE(BOTTOM), [], [e.targets[i]])
                    newEdges.add(bot)
                }
                deadInlinks.add(e)
            }
            case _ => {}
        }
    }

    edges.removeIf({e : Edge => includes(deadInlinks, e)})
    edges.addAll(newEdges)

    for(t in newF.GetTargets()){
        linkConns.add(t, newF.GetConnR(t))
    }
    Hypergraph(name, edges, newF.GetInputs(), outputs, linkConns.toMap())
}