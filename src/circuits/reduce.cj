/**
 * reduce.cj
 *
 * This file contains functions for applying the diagrammatic semantics to
 * reduce circuit hypergraphs to a simpler form
 */

package circuits

import debug.*

/**
 * Resolve links in a hypergraph - join outlinks and inlinks with the same spec together
 * If there are multiple outlinks with the same spec, these are first joined.
 * In between the outlinks and the inlinks an identity edge is placed (this avoids closed loops)
 * If there are multiple inlinks with the same spec, the wire is forked before connecting to them
 * @param f    The hypergraph to resolve links in
 * @param name The name to give the resulting hypergraph
 * @return     The resolved hypergraph
 */
func ResolveLinks(f : Hypergraph, name!: String = ""){
    ResolveLinks(f.Clone(), name: name)
}
/**
 * Resolve links in a hyp builder - join outlinks and inlinks with the same spec together
 * If there are multiple outlinks with the same spec, these are first joined.
 * In between the outlinks and the inlinks an identity edge is placed (this avoids closed loops)
 * If there are multiple inlinks with the same spec, the wire is forked before connecting to them
 * @param f    The hypergraph to resolve links in
 * @param name The name to give the resulting hypergraph
 * @return     The resolved hypergraph
 */
func ResolveLinks(f : HypBuilder, name!: String = ""){
    Debug("ResolveLinks", "Resolving links in ${f.GetName()}")
    let inlinks = f.GetInlinkMap()
    let outlinks = f.GetOutlinkMap()
    // Join all the outlinks into one wire 
    for((spec, outLinkEdges) in outlinks.toMap()){
        match(inlinks.toMap().get(spec)){
            // If there are definitely in links to connect to, we can go ahead
            case Some(inLinkEdges) => {
                let outs = outLinkEdges.size()
                let ins = inLinkEdges.size()
                // Deal with each port of the link in turn
                for(port in 0..spec.width){
                    var currentSource = outLinkEdges[0].sources[port]
                    // We need to join together multiple out links with the same spec
                    if(outs > 1){
                        for(i in 1..outs){
                            // Get the next source
                            let nextSource = outLinkEdges[i].sources[port]
                            // Create a new join with these sources
                            let join = f.CreateEdgeFromExisting(JOIN, [currentSource, nextSource])
                            // Create a new source ready for the next iteration
                            currentSource = f.NewSource(join.targets[0])
                        }
                    }
                    // Create an identity edge in the middle
                    let id = f.CreateEdgeFromExisting(IDENTITY, [currentSource])
                    var currentTarget = id.targets[0]
                    // We need to fork to serve multiple in links with the same spec
                    if(ins > 1){
                        for(i in 0..ins-1){
                            // Go from bottom to top
                            let j = ins - i - 1
                            // Create a fork and connect it to the current target
                            let fork = f.CreateEdge(FORK, [currentTarget])
                            // Set the right target of the fork to connect to whatever the jth target of the outlink connected to
                            f.AddConn(fork.targets[1], inLinkEdges[j].targets[port].GetConn())
                            // Set the left target of the fork ready for the next iteration
                            currentTarget = fork.targets[0]
                        }
                    }
                    // The last port doesn't need forking, we just connect the current target up
                    f.AddConn(currentTarget, inLinkEdges[0].targets[port].GetConn())

                }
                // Remove all the replaced in link edges
                f.RemoveEdges(inLinkEdges)
            }
            // There are no corresponding in links, so we can just stub these outlinks
            case $None => {
                for(e in outLinkEdges){
                    for(s in e.sources){
                        f.CreateEdgeFromExisting(STUB, [s])
                    }
                    f.RemoveEdge(e)
                }
            }
        }
        f.RemoveEdges(outLinkEdges)
    }
    // There may be inlinks that have no corresponding outlink
    // These can be replaced with bottom
    let deadInlinks = f.GetAllInLinks()
    for(link in deadInlinks){
        let spec = link.GetSpec()
        for(i in 0..spec.width){
            f.CreateEdgeFromExisting(VALUE(BOTTOM), [link.targets[i]])
        }
    }    
    f.RemoveEdges({e : Edge => includes(deadInlinks, e)})
    f.ToGraph()
}