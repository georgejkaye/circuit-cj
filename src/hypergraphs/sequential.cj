/**
 * sequential.cj
 *
 * This file contains components to construct sequential circuits with delays and feedback
 */

package hypergraphs

import debug.*

/**
 * Create a delay construct containing a number of delay morphisms 
 * @param dur The duration of the delays
 * @param width The number of delays to make
 * @param output The name of the output bus
 * @param elem The element to begin counting the bus from
 * @param name The name to assign this delay construct
 * @param input The input to this delay construct (m->width)
 * @return The new delay construct, composed with the input if provided
 */
external func Delay(dur!: Int64 = 1, width!: Int64 = 1, output!: String = "", elem!: Int64 = 0, name!: String = "",  input!: Option<Hypergraph> = None<Hypergraph>) : Hypergraph { 
    if(width < 1){
        throw NegativeWireException("Delay")
    }
    let hb = HypBuilder(width, width, output, elem)
    for(i in 0..width){
        hb.CreateEdge(DELAY(dur), [hb.GetInputs()[i]], [hb.GetOutputs()[i]])
    }
    let res = hb.ToGraph(name)
    match(input) {
        case Some(f) => {
            Seq(f, res)
        }
        case $None   => res
    }
}
/**
 * Create a register with an initial value that delays signals for a certain number of clock cycles
 * @param width    The width of this register
 * @param initial  The initial value contained within this register, released on the first clock cycle
 * @param duration The duration of the delay in this register
 * @param output   The label of the output bus
 * @param name     The name to assign this register
 * @param input    The input to this register
 * @return         The new register
 */
external func Register(width!: Int64, initial!: Int64, duration!: Int64 = 0, output!: String = "", name!: String = "", input!: Option<Hypergraph> = None<Hypergraph>) : Hypergraph {
    Debug("Register", "Making regist of width ${width} with initial value ${initial} and duration ${duration}")
    match(input){
    case Some(f) => {
            if(f.GetN() != width){
                  throw BadInputGraphException("Register", "input", width, f.GetName(), f.GetN())
            }
        }
        case $None => {}
    } 
    if(duration < 0){
        throw NegativeDurationException("Register", duration)
    }
    let hb = HypBuilder(width, width, output, 0)
    // Convert the initial value into binary
    let initialBin = DecToBin(width, initial, true)
    // We need to join the ith bit of this number with a delay
    for(i in 0..width){
        // Value for the ith bit of the initial value
        let value = hb.CreateEdge(VALUE(if(initialBin[i]) { TRUE } else { FALSE }))
        // Delay
        let delay = hb.CreateEdge(DELAY(duration), [hb.GetInputs()[i]])
        // Join the value and the delay
        let join = hb.CreateEdge(JOIN, [value.targets[0], delay.targets[0]], [hb.GetOutputs()[i]])
    }
    let reg = hb.ToGraph(name)
    // If we have an input, compose it to the front
    match(input){
        case Some(f) => Seq(f, reg)
        case $None   => reg
    }
}
/**
 * Create an out link for a given link spec
 * @param spec The link spec for this link
 * @param name The name to give this circuit
 * @return The out link
 */
external func OutLink(spec!: LinkSpec, name!: String = "") : Hypergraph { 
    OpMToZero(OUTLINK(spec), name: name) 
}
/**
 * Create an in link for a given link spec
 * @param spec The link spec for this link
 * @param name The name to give this circuit
 * @return The in link
 */
external func InLink(spec!: LinkSpec, output!: String = "", name!:String = "") : Hypergraph { 
    Debug("InLink", "Creating in link for spec ${spec.name}")
    let wires = ArrayList<Wire>(spec.width, {i : Int64 => NewWire(output, i)})
    OpMToN(INLINK(spec), wires: wires, name: name) 
}
/**
 * Create a iteration: a construct that feeds its outputs back to some in link while also outputting them
 * @param spec   The link spec for the loop
 * @param output The name to assign the output bus
 * @param name   The name to give this circuit
 * @return The iteration
 */
external func Feedback(spec!: LinkSpec, output!: String = "", name!: String = "", input!: Option<Hypergraph> = None<Hypergraph>) : Hypergraph {
    let hb = HypBuilder(spec.width, spec.width, output)
    let link = hb.CreateEdge(OUTLINK(spec))
    for(i in 0..spec.width){
        let fork = hb.CreateEdge(FORK, [hb.GetInputs()[i]], [link.sources[i], hb.GetOutputs()[i]])
    }
    let res = hb.ToGraph()
    match(input){
        case Some(f) => Seq(f, res)
        case $None   => res
    }
}