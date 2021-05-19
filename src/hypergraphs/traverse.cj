/**
 * traverse.cj
 *
 * This file contains functions to traverse hypergraphs
 */

package hypergraphs

import debug.*

/**
 * Get all the endpoints of a hypergraph: the outputs and the sources of any edge with no targets
 * @param f The hypergraph
 * @return The list of sources that are either outputs or sources to edges with no targets
 */
func GetEndpoints(f : Hypergraph){
    let vs = ArrayList<Source>(f.GetOutputs())
    for(e in f.GetEdges()){
        if(e.targets.size() == 0){
            vs.addAll(e.sources)
        }
    }
    vs
}

func TraverseLeft(f : Hypergraph, s : Source, edgeAction : (Edge) -> Unit, inputAction : (Target, Int64) -> Unit){

    let frontier = ArrayList<Source>([s])
    let visitedSources = ArrayList<Source>()
    let visitedTargets = ArrayList<Target>()
    let visitedInputs = ArrayList<Target>()
    let visitedEdges = ArrayList<Edge>()

    while(frontier.size() != 0){
        let s = frontier.removeAt(0)
        visitedSources.add(s)
        let t = f.GetConnL(s)
        visitedTargets.add(t)
        match(f.GetEdge(t)){
            case EdgePort(e, i) => {
                if(!includes(visitedEdges, e)){
                    visitedEdges.add(e)
                    edgeAction(e)
                    frontier.addAll(e.sources)
                }
            }
            case InterfacePort(i) => {
                visitedInputs.add(t)
                inputAction(t, i)
            }
        }
    }
    (visitedEdges, visitedSources, visitedTargets, visitedInputs)
}