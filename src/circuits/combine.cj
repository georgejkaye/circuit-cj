/**
 * combine.cj
 *
 * This file contains methods for combining hypergraphs.
 */

package circuits

import debug.*

/**
 * Find the points that a graph g diverges from a base graph f
 * @param f The base graph
 * @param g The graph to check for divergence points
 * @return A list of pairs of sources from f and g where the two graphs diverge
 */
func FindDivergencePoints(f : HypergraphStructure, g : HypergraphStructure){
    Debug("FindDivergencePoints", "Finding divergence points between '${f.GetName()}'' and '${g.GetName()}'")
    let fids = f.GetEdgeGlobalIds()

    let frontier = ArrayList<Source>(g.GetOutputs())
    let ends = g.GetEdgesWithProperty({e : Edge => e.targets.size() == 0})

    for(e in ends){
        match(fids.toMap().get(e.globalId)){
            case $None => frontier.addAll(e.sources)
            case _ => () 
        }
    }
    let divergencePoints = ArrayList<Source * Source>()
    let encounteredEdges = ArrayList<Edge>()

    while(frontier.size() != 0){
        let s = frontier.removeAt(0)
        match(s.GetLeftPort()){
            case EdgePort(e, i) => 
                let cont = match(fids.toMap().get(e.globalId)){
                    case Some(fe) => 
                        divergencePoints.add((fe.GetTarget(i).GetConn(), s))
                        false
                    case $None =>
                        !includes(encounteredEdges, e)
                }
                encounteredEdges.add(e)
                if(cont){
                    frontier.addAll(e.sources)
                }
            case InterfacePort(i) => ()
        }
    }
    divergencePoints
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
    Debug("Inject", "Injecting '${g.GetName()}' into '${f.GetName()}'")
    // Find out all the edges in g that have a corresponding edge in f
    // These are edges with the same global id
    let fids = f.GetEdgeGlobalIds()
    let duplicateEdges = g.GetEdgesWithProperty({e : Edge => 
        match(fids.toMap().get(e.globalId)){
            case Some(fe) => true
            case $None   => false
    }})
    // Remove all the edges in g that have a corresponding edge in f
    g.RemoveEdges(duplicateEdges)
    // Some of the inputs of g may also exist in f
    // Not necessarily all of them, e.g. g could have some additional identity at the bottom
    let inids = f.GetTargetGlobalIds()
    let duplicateInputs = g.GetInputsWithProperty({t : Target =>
        match(inids.toMap().get(t.globalId)){
            case Some(ft) => true
            case $None   => false
    }})
    g.RemoveInputs(duplicateInputs)
    // Add the remaining bits of g into f
    f.AddNewGraph(g)
    // Create a fork for each intersection point so that we can include the content of both f and g
    for((intersectionF, intersectionG) in intersections){
        PerformInjection(f, intersectionF, intersectionG)
    }
    // We're done!
    f
}
/**
 * For a source vertex from f and g, create a fork edge with targets that connect to them
 * The source of this fork edge will be the 'left' of f
 * @param f The 'base' hyp builder to perform the injection in
 * @param sf The intersection vertex of f
 * @param sg The intersection vertex of g
 */
func PerformInjection(f : HypBuilder, sf : Source, sg : Source){
    // Make note of the target from f we are about to disconnect
    let danglingTarget = sg.GetConn()
    // Make a new fork
    let fork = f.CreateEdge(FORK)
    // The source of the fork is the 'intersection point'
    // We add any wires from the two intersections
    f.AddWires(fork.GetSource(0), sf.wires)
    f.AddWires(fork.GetSource(0), sg.wires)
    // Hook the fork up to everything
    f.AddConn(sf.GetConn(), fork.GetSource(0))
    f.AddConn(fork.GetTarget(0), sf)
    f.AddConn(fork.GetTarget(1), sg)
    // Refresh the wires in the intersection points
    // We don't want to duplicate the intersected wires
    f.RefreshWires(sf)
    f.RefreshWires(sg)
    danglingTarget
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
                ()
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