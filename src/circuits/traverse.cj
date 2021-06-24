/**
 * traverse.cj
 *
 * This file contains functions to traverse hypergraphs
 */

package circuits

import debug.*

/**
 * Get all the startpoints of a hypergraph: the inputs and the targets of any edge with no sources
 * @param f The hypergraph
 * @return The list of sources that are either inputs or targets of edges with no sources
 */
func GetStartpoints(f : HypergraphStructure){
    let vs = ArrayList<Target>(f.GetInputs())
    f.ForEachEdgeWithProperty(
        {e : Edge => e.sources.size() == 0 || e.IsIdentity()},
        {e : Edge => vs.addAll(e.targets)}
    )
    vs
}
/**
 * Get all the endpoints of a hypergraph: the outputs and the sources of any edge with no targets
 * @param f The hypergraph
 * @return The list of sources that are either outputs or sources of edges with no targets
 */
func GetEndpoints(f : HypergraphStructure){
    let vs = ArrayList<Source>(f.GetOutputs())
    f.ForEachEdgeWithProperty(
        {e : Edge => e.targets.size() == 0 || e.IsIdentity()},
        {e : Edge => vs.addAll(e.sources)}
    )
    vs
}
/**
 * Traverse through a graph leftwards from a given source
 * @param s The source to start traversing from
 * @param edgeAction The action to take at each edge: takes the current edge and the incoming target as argument, and returns
                     a bool dictating if traversal should continue or halt
 * @param inputAction The action to take at each reached input: takes the input vertex and its index in the inputs list and returns unit
 */
func TraverseLeft(s : Source, edgeAction : (Edge, Target) -> Bool, inputAction : (Target, Int64) -> Unit){
    TraverseLeft(s.GetConn(), edgeAction, inputAction)
}
/**
 * Traverse through a graph leftwards from a given target
 * @param s The source to start traversing from
 * @param edgeAction The action to take at each edge: takes the current edge and the incoming target as argument, and returns
                     a bool dictating if traversal should continue or halt
 * @param inputAction The action to take at each reached input: takes the input vertex and its index in the inputs list and returns unit
 */
func TraverseLeft(t : Target, edgeAction : (Edge, Target) -> Bool, inputAction : (Target, Int64) -> Unit){
    let frontier = ArrayList<Target>([t])
    let visitedSources = ArrayList<Source>()
    let visitedTargets = ArrayList<Target>()
    let visitedInputs = ArrayList<Target>()
    let visitedEdges = ArrayList<Edge>()

    while(frontier.size() != 0){
        let t = frontier.removeAt(0)
        visitedTargets.add(t)
        match(t.GetPort()){
            case EdgePort(e, i) =>
                if(!includes(visitedEdges, e)){
                    visitedEdges.add(e)
                    let cont = edgeAction(e, t)
                    if(cont){
                        for(s in e.sources){
                            visitedSources.add(s)
                            frontier.add(s.GetConn())
                        }
                    }
                }
            case InterfacePort(i) =>
                visitedInputs.add(t)
                inputAction(t, i)
        }
    }
    (visitedEdges, visitedSources, visitedTargets, visitedInputs)
}

/**
 * Traverse through this graph rightwards from a given target
 * @param f The hypergraph structure to traverse
 * @param s The source to start traversing from
 * @param edgeAction The action to take at each edge: takes the current edge and the incoming source as argument, and returns
                     a bool dictating if traversal should continue or halt
 * @param outputAction The action to take at each reached output: takes the output vertex and its index in the outputs list and returns unit
 */
func TraverseRight(t : Target, edgeAction : (Edge, Source) -> Bool, outputAction : (Source, Int64) -> Unit){

    let frontier = ArrayList<Target>([t])
    let visitedSources = ArrayList<Source>()
    let visitedTargets = ArrayList<Target>()
    let visitedInputs = ArrayList<Target>()
    let visitedEdges = ArrayList<Edge>()

    while(frontier.size() != 0){
        let t = frontier.removeAt(0)
        let s = t.GetConn()
        visitedSources.add(s)
        visitedTargets.add(t)
        match(s.GetPort()){
            case EdgePort(e, i) =>
                if(!includes(visitedEdges, e)){
                    visitedEdges.add(e)
                    let cont = edgeAction(e, s)
                    if(cont){
                        frontier.addAll(e.targets)
                    }
                }
            case InterfacePort(i) =>
                visitedInputs.add(t)
                outputAction(s, i)
        }
    }
    (visitedEdges, visitedSources, visitedTargets, visitedInputs)
}
/**
 * Perform a full traversal of a hypergraph structure, starting from the inputs 
 * and performing an action at each edge
 * @param f The hypergraph structure to traverse
 * @param edgeAction The action to perform at each edge
 */
func FullTraverse(f : HypergraphStructure, edgeAction : (Edge) -> Unit){
    let frontier = GetStartpoints(f)
    let visited = ArrayList<Edge>()

    for(t in frontier){
        match(t.GetRightPort()){
            case EdgePort(e, i) => {
                if(!includes(visited, e)){
                    edgeAction(e)
                    visited.add(e)
                    frontier.addAll(e.targets)
                }  
            }
            case InterfacePort(i) => {}
        }
    }
}
/**
 * Is there a path to the outputs from a given edge?
 * @param e The edge to traverse from
 * @return Whether there is a path to the outputs from this edge
 */
func PathToOutputs(e : Edge){
    let visited = ArrayList<Edge>()
    let frontier = ArrayList<Target>(e.targets)
    while(frontier.size() != 0){
        let t = frontier.removeAt(0)
        if(t.HasConn()){
            let s = t.GetConn()
            if(s.HasPort()){
                match(s.GetRightPort()){
                    case InterfacePort(i) => return true
                    case EdgePort(e1, i) => 
                        if(!includes(visited, e1)){
                            visited.add(e1)
                            frontier.addAll(e1.targets)
                        }
                }
            }
        }
    }
    return false
}