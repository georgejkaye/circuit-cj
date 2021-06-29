/**
 * sequential.cj
 *
 * This file contains functions to define the input and output interfaces to circuits
 */

package circuits

import debug.*

/**
 * Create an input to the graph with associated handles
 * @param out The name of the bus
 * @param width The width of the bus
 * @return The input circuit
 */
external func Input(label!: String = "", width!: Int64 = 1){
    if(width < 1){
        throw NegativeWireException("Input")
    }
    //let bus = NewBus(label)
    Identity(width, label: label)
}
/**
 * Combine a list of hypergraphs into a single hypergraph, ensuring that any shared wires are
 * shared in the resulting hypergraph. The order of the outputs is determined by the 
 * order the hypergraphs are given in
 * @param fs   The list of hypergraphs
 * @param name The name of the resulting hypergra
 * @return     The combined hypergraph
 */
external func Concat(fs : ArrayList<Hypergraph>, name!: String = ""){
    Debug("Concat", "Concatting hypergraphs")
    var f = fs[0].Clone()
    for(i in 1..fs.size()){
        var g = fs[i].Clone()
        let intersections = FindIntersections(f, g)
        WriteDotToFile(f.ToGraph(), "f1")
        WriteDotToFile(g.ToGraph(), "g1")
        if(intersections.size() == 0){
            f.AddNewGraph(g)
        } else {
            f = Inject(f, g, intersections)
        }
    }
    let re = f.ToGraph()
    re
}
/**
 * Combine a list of hypergraphs into a single hypergraph, ensuring that any shared wires are
 * shared in the resulting hypergraph. The order of the outputs is determined by the 
 * order the hypergraphs are given in
 * @param fs   The list of hypergraphs
 * @param name The name of the resulting hypergraph
 */
external func Concat(fs : List<Hypergraph>, name!: String = ""){
    Concat(ArrayList<Hypergraph>(fs), name: name)
}