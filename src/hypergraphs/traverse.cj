/**
 * traverse.cj
 *
 * This file contains functions to traverse hypergraphs
 */

package hypergraphs

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