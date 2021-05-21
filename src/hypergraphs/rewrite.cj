/**
 * rewrite.cj
 *
 * This file contains methods for rewriting hypergraphs.
 */

package hypergraphs

import debug.*

/**
 * Find intersections between f and g - i.e. wires in f that also exist in g
 * @param f The first hypergraph
 * @param g The second hypergraph
 * @return A tuple of three lists representing the intersections of f and g:
 *                    - The source vertices of f that are intersections
 *                    - The source vertices of g that are intersections
 *                    - The ports of g that the intersections connect to
 */ 
func FindIntersections(f : HypergraphStructure, g : HypergraphStructure){
    Debug("FindIntersection", "Finding intersections between ${f.GetName()} and ${g.GetName()}")
    // The list of source vertice of intersections in f and g
    let intersectionsF = ArrayList<Source>()
    let intersectionsG = ArrayList<Source>()
    // Traverse backwards from the outputs of g to find wires also in f
    let visited = ArrayList<Edge>()
    let frontier = ArrayList<Source>(GetEndpoints(g))
    let wires = f.GetWires()
    while(frontier.size() != 0){
        let v : Source = frontier.removeAt(0)
        var found = false
        for(w in v.wires){
            // Check if the wire is also in f, if so add it to the lists
            if(!found && !includes(intersectionsG, v) && includes(wires, w)){
                // Add the corresponding vertex for f for this wire
                intersectionsF.add(f.GetWireVertex(w))
                intersectionsG.add(v)
                // We don't need to check for any more wires in this vertex now
                found = true
            }
        }
        // If we didn't find an intersection, add the next edge to our frontier
        if(!found){
            let p = v.GetConn().GetPort()
            match(p) {
                case EdgePort(e, i) => {
                    if(!includes(visited, e)){
                        frontier.addAll(e.sources)
                    }       
                }
                case InterfacePort(i) => {}
            }
        }
    }
    print("intersections ${PrintList(intersectionsF, {s : Source => PrintList(s.wires)})}\n")
    (intersectionsF, intersectionsG)
}

/**
 * Remove all parts of the graph that are 'left' of a list of source vertices
 * Any dangling targets will be capped off with bottom
 * @param g  The hypergraph builder
 * @param vs The list of source vertices to remove from
 * @return A clone of the hypergraph with all parts of the hypergraph left of a given source vertex removed
 */
func RemoveLeft(g : HypBuilder, vs : ArrayList<Source>){
    Debug("RemoveLeft", "Removing left ${g.GetName()} from ${SourceListToString(vs)}")
    let removedEdges = ArrayList<Edge>()
    let removedInputs = ArrayList<Target>()
    let edgeAction = {e : Edge => if(!includes(removedEdges, e)){ removedEdges.add(e) }}
    let inputAction = {t : Target, i : Int64 => if(!includes(removedInputs, t)){ removedInputs.add(t) }}

    for(sg in vs){
        let t = TraverseLeft(g, sg, edgeAction, inputAction)
    }

    g.RemoveEdges(removedEdges)
    g.RemoveInputs(removedInputs)

    // Cap off any dangling vertices that are not in the list of removal points
    for(e in g.GetEdges()){
        for(s in e.sources){
            if(!includes(vs, s)){
                let t = s.GetConn()
                match(t.GetPort()){
                    case EdgePort(e1, i) => {
                        if(includes(removedEdges, e1)){
                            g.CreateEdgeFromExisting(VALUE(BOTTOM), ArrayList<Target>([t]))
                        }
                    }
                    case InterfacePort(i) => {}
                }
            }
        }
    }
    g
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
 * @param intersectionsF The list of intersection points in f
 * @param g The hypergraph to be injected
 * @param intersectionsG The list of intersection points in g
 * @return A clone of hypergraph f with a clone of g injected into it
 */
func Inject(f : HypBuilder, intersectionsF : ArrayList<Source>, g : HypBuilder, intersectionsG : ArrayList<Source>){
    Debug("Inject", "Injecting into ${f.GetName()}")

    f.AddNewGraph(g)

    // Inject each of the vertices we have recovered
    for(i in 0..intersectionsF.size()){
        var fork = true

        // If the intersection point leads to a non-output endpoint of the graph, we need to be clever
        // If it's a stub, we can just drop it as there is no benefit to forking to a stub
        // If it's an outlink, we need to check if the other intersection point leads to the same link
        // Therefore we need to keep track of it
        let outlinkF = match(PortToEndpoint(intersectionsF[i].GetPort())){
            case Some((e, j)) => {
                match(e.generator){
                    // If we find a stub, then we don't need to copy it
                    case STRUCTURAL(struct) => {
                        f.RemoveEdge(e)
                        f.AddConn(intersectionsF[i].GetConn(), intersectionsG[i])
                        fork = false
                        None<LinkSpec>
                    }
                    case OUTLINK(specf) => { Some(specf) }
                    case _              => { None<LinkSpec> }
                }
            }
            case $None => { None<LinkSpec> }
        }
        // If we've already decided to not fork then we immediately just take the content of g
        if(fork) {
            // Ditto for the outlink of g
            match(PortToEndpoint(intersectionsF[i].GetPort())){
                case Some((e, j)) => {
                    match(e.generator){
                        // Once again we can ignore stubs
                        // This is a lot easier for g, as it is not the 'base' graph
                        // We can just make a note to delete the stub edge
                        case STRUCTURAL(struct) => {
                            f.RemoveEdge(e)
                            fork = false    
                        }
                        // If this and f also lead to an outlink, we can check them to see if they're the same
                        // If so, there's no point in copying 
                        case OUTLINK(specg) => {
                            match(outlinkF){
                                case Some(specf) => {
                                    f.RemoveEdge(e)
                                    fork = false
                                }
                                case $None => {}
                            }   
                        }
                        case _ => {}
                    }
                }
                case $None => {}
            }
        }
        // If we are still satified that a fork is truly required, go for it
        if(fork){
            // Grab the ports of the intersection sources
            let portF = intersectionsF[i].GetPort()
            let portG = intersectionsG[i].GetPort()
            // Make a new fork
            let edge = f.CreateEdgeFromExisting(FORK, [intersectionsF[i]])
            // Hook up f and g to this new fork, creating new sources
            f.NewSource(portF, edge.targets[0])
            f.NewSource(portG, edge.targets[1])
        }
    }
    f
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
func Extract(f : HypBuilder, buses : ArrayList<String>, name!: String = "") : Hypergraph {
    Debug("Extract", "Extracting buses ${PrintList(buses)} from '${f.GetName()}'")
    
    // Find the vertices that correspond to the buses
    var vs = ArrayList<Source>()
    for(bus in buses){
        vs = f.GetBusVertexList(bus, vs)
    }
    // Set up structures to track the new atoms
    let newEdges = ArrayList<Edge>(f.GetEdges())
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
        t1.SetConn(s1)
        t2.SetConn(s2)
        // If we have already forked this wire, we need to set the sources
        // of the new fork we created rather than those of the original edge
        let out = match(doneMap.toMap().get(s)){
            case Some(e) => {
                e.sources.set(0, s1)
                s2
            }
            case $None => {
                match(s.GetPort()){
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
    Hypergraph(name, newEdges, f.GetInputs(), newOutputs)
}

/**
 * Resolve links in a hypergraph - join outlinks and inlinks with the same spec together
 * If there are multiple outlinks with the same spec, these are first joined.
 * In between the outlinks and the inlinks an identity edge is placed (this avoids closed loops)
 * If there are multiple inlinks with the same spec, the wire is forked before connecting to them
 * @param f    The hypergraph to resolve links in
 * @param name The name to give the resulting hypergraph
 * @return     The resolved hypergraph
 */
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

    Hypergraph(name, edges, newF.GetInputs(), outputs)
}