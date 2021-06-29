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
func ResolveLinks(f : Hypergraph, name!: String = "") {
    let f = f.Clone()
    ResolveLinks(f, name: name)
    f
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
func ResolveLinks(f : HypBuilder, name!: String = "") {
    Debug("ResolveLinks", "Resolving links in ${f.GetName()}")
    let inlinks = f.GetInlinkMap()
    let outlinks = f.GetOutlinkMap()
    // Join all the outlinks into one wire 
    for((spec, outLinkEdges) in outlinks){
        match(inlinks.get(spec)){
            // If there are definitely in links to connect to, we can go ahead
            case Some(inLinkEdges) =>
                let outs = outLinkEdges.size()
                let ins = inLinkEdges.size()
                // Deal with each port of the link in turn
                for(port in 0..spec.width){
                    var currentTarget = outLinkEdges[0].sources[port].GetConn()
                    // We need to join together multiple out links with the same spec
                    if(outs > 1){
                        for(i in 1..outs){
                            // Get the next source
                            let nextTarget = outLinkEdges[i].sources[port].GetConn()
                            // Create a new join with these sources
                            let join = f.CreateEdge(JOIN)
                            f.AddConn(currentTarget, join.GetSource(0))
                            f.AddConn(nextTarget, join.GetSource(1))
                            // Create a new source ready for the next iteration
                            currentTarget = join.GetTarget(0)
                        }
                    }
                    // Create an identity edge in the middle
                    let id = f.CreateEdge(IDENTITY)
                    f.AddConn(currentTarget, id.GetSource(0))
                    currentTarget = id.GetTarget(0)
                    // We need to fork to serve multiple in links with the same spec
                    if(ins > 1){
                        for(i in 0..ins-1){
                            // Go from bottom to top
                            let j = ins - i - 1
                            // Create a fork and connect it to the current target
                            let fork = f.CreateEdge(FORK, [currentTarget])
                            // Set the right target of the fork to connect to whatever the jth target of the outlink connected to
                            f.AddConn(fork.GetTarget(1), inLinkEdges[j].targets[port].GetConn())
                            // Set the left target of the fork ready for the next iteration
                            currentTarget = fork.GetTarget(0)
                        }
                    }
                    // The last port doesn't need forking, we just connect the current target up
                    f.AddConn(currentTarget, inLinkEdges[0].targets[port].GetConn())

                }
                // Remove all the replaced in link edges
                f.RemoveEdges(inLinkEdges)
            // There are no corresponding in links, so we can just stub these outlinks
            case $None =>
                for(e in outLinkEdges){
                    for(s in e.sources){
                        let stub = f.CreateEdge(STUB)
                        f.AddConn(s.GetConn(), stub.GetSource(0))
                    }
                    f.RemoveEdge(e)
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
            let bot = f.CreateEdge(VALUE(BOTTOM))
            f.AddConn(bot.GetTarget(0), link.targets[i].GetConn())
        }
    }    
    f.RemoveEdges({e : Edge => includes(deadInlinks, e)})
}
/**
 * Undoes the actions of ResolveLinks and creates links where there used to be identity edges
 * Modifies the provided hyp builder
 */
func UnresolveLinks(f : HypBuilder){
    let ids = f.GetAllIdentityEdges()
    for(e in ids){
        let spec = NewLink()
        let outlink = f.CreateEdge(OUTLINK(spec))
        f.AddConn(e.GetSource(0).GetConn(), outlink.GetSource(0))
        let inlink = f.CreateEdge(INLINK(spec))
        f.AddConn(inlink.GetTarget(0), e.GetTarget(0).GetConn())
        f.RemoveEdge(e)
    }
}