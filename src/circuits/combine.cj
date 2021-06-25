/**
 * combine.cj
 *
 * This file contains methods for combining hypergraphs.
 */

package circuits

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
    let intersections = ArrayList<Source * Source>()
    // Traverse backwards from the outputs of g to find wires also in f
    let visited = ArrayList<Edge>()
    let frontier = ArrayList<Source>(GetEndpoints(g))
    let wires = f.GetWires()

    while(frontier.size() != 0){
        let v : Source = frontier.removeAt(0)
        var found = false
        if(!includesPairR(intersections, v)){
            for(w in v.wires){
                // Check if the wire is also in f, if so add it to the lists
                if(!found && includes(wires, w)){
                    // Add the corresponding vertex for f for this wire
                    intersections.add((f.GetWireVertex(w), v))
                    // We don't need to check for any more wires in this vertex now
                    found = true
                }
            }
            // If we didn't find an intersection, add the next edge to our frontier
            if(!found){
                let p = v.GetConn().GetPort()
                match(p) {
                    case EdgePort(e, i) =>
                        if(!includes(visited, e)){
                            frontier.addAll(e.sources)
                        }       
                    case InterfacePort(i) => ()
                }
            }
        }
    }
    intersections
}

/**
 * Inject a hypergraph g into a hypergraph f (g >> f)
 * For all inputs of g, find a corresponding wire in f and fork it
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
 * If one of the intersections connects to a stub in f or g, only the non-stub edge will be connected up
 * If the intersections both connect to the same outlink, then only one is preserved
 * If any of the input wires of g does not exist in f, then throws an exception
 *
 * @param f The hypergraph to be injected into
 * @param g The hypergraph to be injected
 * @param intersections The list of pairs of intersections in f and g
 * @return A clone of hypergraph f with a clone of g injected into it
 */
func Inject(f : HypBuilder, g : HypBuilder, intersections : ArrayList<Source * Source>){
    Debug("Inject", "Injecting")
    let removedEdges = ArrayList<Edge>()
    let removedInputs = ArrayList<Target>()
    let removedIntersections = ArrayList<Source>()

    let danglingTargets = ArrayList<Target>()

    f.AddNewGraph(g)

    // Inject each of the vertices we have recovered
    for((intersectionF, intersectionG) in intersections){
        var fork = true
        // If the intersection point leads to a non-output endpoint of the graph, we need to be clever
        // If it's a stub, we can just drop it as there is no benefit to forking to a stub
        // If it's an outlink, we need to check if the other intersection point leads to the same link
        // Therefore we need to keep track of it
        let outlinkF = match(PortToEndpoint(intersectionF.GetPort())){
            case Some((e, j)) =>
                match(e.generator){
                    // If we find a stub, then we don't need to copy it
                    // We just hook up the source of the stub to the intersection with g
                    case STRUCTURAL(struct) =>
                        removedEdges.add(e)
                        danglingTargets.add(intersectionG.GetConn())
                        f.AddConn(intersectionF.GetConn(), intersectionG)
                        fork = false
                        None<LinkSpec>
                    case OUTLINK(specf) => Some<LinkSpec>(specf)
                    case _              => None<LinkSpec>
                }
            case $None => None<LinkSpec>
        }
        // If we've already decided to not fork then we immediately just take the content of g
        if(fork) {
            // We need to check if the intersection sources lead to endpoints
            match(PortToEndpoint(intersectionG.GetPort())){
                case Some((e, j)) =>
                    match(e.generator){
                        // Once again we can ignore stubs
                        // This is a lot easier for g, as it is not the 'base' graph
                        case STRUCTURAL(struct) =>
                            removedEdges.add(e)
                            danglingTargets.add(intersectionG.GetConn())
                            fork = false    
                        // If this and f also lead to an outlink, we can check them to see if they're the same
                        // If so, there's no point in copying: we can just keep the link from f and ignore this one
                        case OUTLINK(specg) =>
                            match(outlinkF){
                                case Some(specf) =>
                                    if(specf == specg) {
                                        removedEdges.add(e)
                                        fork = false
                                    }
                                case $None => ()
                            }   
                        case _ => ()
                    }
                case $None => ()
            }
        }
        // If we are still satified that a fork is truly required, go for it
        if(fork){
            // Grab the ports of the intersection sources
            let portF = intersectionF.GetPort()
            let portG = intersectionG.GetPort()
            // Make a new fork
            let fork = f.CreateEdge(FORK)
            // HACK inline access arraylist creates segfault
            let s = fork.GetSource(0)
            f.AddConn(intersectionF.GetConn(), s)
            // Hook up f and g to this new fork, creating new sources
            let t1 = fork.GetTarget(0)
            f.AddConn(t1, intersectionF)
            danglingTargets.add(intersectionG.GetConn())
            let t2 = fork.GetTarget(1)
            f.AddConn(t2, intersectionG)    
        }
    }
    // Functions to use when traversing the graph to find the dangling elements
    // Track any dangling edges
    let edgeAction = { e : Edge, t : Target =>
            if(!(includes(removedEdges, e))){
                removedEdges.add(e)
                true
            } else {
                false
            }
    }
    // Track any dangling inputs
    let inputAction = { t : Target , i : Int64 => 
        removedInputs.add(t)
    }
    // Find all the bits of g that have been left dangling
    for(t in danglingTargets){
        TraverseLeft(t, edgeAction, inputAction)
    }
    // Remove any dangling edges
    for(edge in removedEdges){
        f.RemoveEdge(edge)
    }
    // Remove any dangling inputs
    f.RemoveInputs(removedInputs)
    // We're done!
    f
}

/**
 * Fork some given source vertices and send the new copy to the outputs.
 * Original outputs are stubbed.
 * Order of the new outputs is determined by the order of the given list
 * @param f  The hypergraph to extract the vertices from
 * @param vs The list of source vertices to extract
 * @return The hypergraph with the source vertices extracted
 */
func Extract(f : HypBuilder, buses : ArrayList<String>, name!: String = "") : Hypergraph {
    Debug("Extract", "Extracting buses from '${f.GetName()}'")
    
    // Find the vertices that correspond to the buses
    let vs = ArrayList<Source>()
    for(bus in buses){
        f.GetBusVertexList(bus, vs)
    }
    let oldOutputs = ArrayList<Source>(f.GetOutputs())
    f.ConnectEachOutputToEdge(STUB)
    for(i in 0..vs.size()){
        let s = vs[i]
        let p = s.GetPort()
        // If p goes to a stub, then we don't need to bother forking, we can send it straight to the outputs
        match(PortToGenerator(p, STUB)){
            case Some((e, _)) =>
                f.RemoveEdge(e)
                f.AddOutput(s)
            case $None =>
                let fork = f.CreateEdge(FORK)
                f.AddConn(s.GetConn(), fork.GetSource(0))
                f.AddConn(fork.GetTarget(0), s)
                // Add the output at the appropriate place
                let out = Source()
                f.SetOutput(i, out)
                f.AddConn(fork.GetTarget(1), out)
        }
    }
    f.ToGraph(name)
}