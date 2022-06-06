package examples

import circuits.*

/**
 * Naive sorting network
 * @param width The width of the input wires
 * @param inputs The number of inputs to sort
 */
func SortingNetwork(width: Int64, inputs: Int64) : Hypergraph {
    if(inputs < 1){
        Empty()
    } else if (inputs == 1){
        Identity(width)
    } else {
        var circ = SortingNetwork(width, inputs - 1) * Identity(width)
        for(i in 0..inputs - 1){
            let j = inputs - i - 2
            var slice = Empty()
            for(k in 0..inputs - 1){
                if (k == j){
                    slice = slice * SortingComparator(width)
                } else {
                    slice = slice * Identity(width)
                }
            }
            circ = circ + slice
        }
        circ
    }
}

func SortingComparator(width: Int64){
    BlackBox("cmp", 2 * width, 2 * width)
}