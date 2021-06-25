/**
 * sequential.cj
 *
 * This file contains components to construct sequential circuits with delays and feedback
 */

package circuits

import debug.*

/**
 * Is this source vertex the start of a waveform?
 * @param s The source vertex
 * @return Whether this source vertex is the start of a waveform
 */
func IsWaveformArg(s : Source){
    match(s.GetLeftPort()){
        case EdgePort(e, i) => IsWaveform(e)
        case InterfacePort(i) => None<Waveform>
    }
}
/**
 * Is an edge the start of a waveform?
 * It must be a join and have a value and delay argument
 * @param edge The edge to check
 * @return The waveform structure if it is one, or None otherwise
 */
func IsWaveform(edge : Edge){
    if(edge.generator != JOIN){
        return None<Waveform>
    }
    let lhsSource = edge.GetSource(0)
    let lhsArg = lhsSource.GetLeftPort()
    let rhsSource = edge.GetSource(1)
    let rhsArg = rhsSource.GetLeftPort()
    let value : Edge 
    let delay : Edge
    if(IsValue(lhsArg) && IsDelay(rhsArg)){
        value = lhsSource.GetLeftEdge()
        delay = rhsSource.GetLeftEdge()
    } else if (IsValue(rhsArg) && IsDelay(lhsArg)){
        value = rhsSource.GetLeftEdge()
        delay = lhsSource.GetLeftEdge()
    } else {
        // The arguments of the join do not have an immediate component and a delayed component
        return None<Waveform>
    }
    Some<Waveform>(Waveform(value, edge, delay))
}
/**
 * Class to keep track of the components of a waveform
 * a) The value edge, the head of the waveform
 * b) The delay edge, leading to the rest of the waveform
 * c) The join edge, connecting the two
 */
class Waveform {
    let value : Edge
    let join : Edge
    let delay : Edge
    init(value : Edge, join : Edge, delay : Edge){
        if(!value.IsValue()){
            throw NonValueEdgeException("Waveform", value)
        }
        this.value = value
        if(join.generator != JOIN){
            throw NonJoinEdgeException("Waveform", join)
        }
        this.join = join
        if(!delay.IsDelay()){
            throw NonDelayEdgeException("Waveform", delay)
        }
        this.delay = delay
    }
}
/**
 * Crete a waveform from a list of numbers
 * A waveform is a sequence of values with delays in between each one
 * @param xs The list of numbers
 * @param width The width of each value
 * @param signed Whether the numbers should be signed
 * @return The hypbuilder for this waveform
 */
func CreateWaveform(xs : List<Int64>, width!: Int64, signed!: Bool = false){
    CreateWaveform(ArrayList<Int64>(xs), width: width, signed: signed)
}
/**
 * Crete a waveform from a list of numbers
 * A waveform is a sequence of values with delays in between each one
 * @param xs The list of numbers
 * @param width The width of each value
 * @param signed Whether the numbers should be signed
 * @return The hypbuilder for this waveform
 */
func CreateWaveform(xs : ArrayList<Int64>, width!: Int64, signed!: Bool = false) : HypBuilder {
    if(xs.size() == 0){
        HypBuilder()    
    } else if (xs.size() == 1){
        CreateValueFromInt(xs[0], width: width, signed: signed)
    } else {
        let headNumber = xs.removeAt(0)
        let head = CreateValueFromInt(headNumber, width: width, signed: signed)
        let tail : HypBuilder = CreateWaveform(xs, width: width, signed: signed)

        head.AddNewGraph(tail)

        for(i in 0..width){
            let now = head.GetOutput(i)
            let join = head.CreateEdge(JOIN)
            let delay = head.CreateEdge(DELAY(1))
            head.AddConn(now.GetConn(), join.GetSource(0))
            head.AddConn(join.GetTarget(0), now)
            head.AddConn(tail.GetOutput(i).GetConn(), delay.GetSource(0))
            head.AddConn(delay.GetTarget(0), join.GetSource(1))
        }
        head.RemoveOutputs(tail.GetOutputs())
        head
    }
}
/**
 * Create a waveform from a list of numbers
 * @param xs The list of numbers to translate
 * @param width The width of the values in the waveform
 * @param signed Whether the values are signed
 * @param name The name of the waveform
 * @return The waveform
 */
external func WaveformFromList(xs : List<Int64>, width!: Int64, signed!: Bool = false, name!: String = ""){
    Debug("WaveformFromList", "Creating waveform from list ${PrintList(ArrayList<Int64>(xs), {i : Int64 => "${i}"})}")
    let waveform = CreateWaveform(xs, width: width, signed: signed)
    waveform.ToGraph(name)
}
/**
 * Create a waveform that produces a given value infinitely
 * @param value The value this waveform produces
 * @param width The width of the waveform
 * @param name The name to assign the waveform
 * @param signed Whether or not the value is signed
 * @return The infinite waveform builder
 */
func CreateInfiniteWaveform(value : Int64, width!: Int64, name!: String = "", signed!: Bool = false){
    Debug("InfiniteWaveform", "Creating infinite waveform for value ${value}")
    let hb = CreateIdentity(width)
    PrependHead(value, hb, signed: signed)
    for(i in 0..width){
        let fork = hb.CreateEdge(FORK)
        hb.AddConn(hb.GetOutput(i).GetConn(), fork.GetSource(0))
        print("a\n")
        hb.AddConn(fork.GetTarget(1), hb.GetOutput(i))
        print("b\n")
        let spec = NewSpec()
        let outlink = hb.CreateEdge(OUTLINK(spec))
        hb.AddConn(fork.GetTarget(0), outlink.GetSource(0))
        print("c\n")
        let inlink = hb.CreateEdge(INLINK(spec))
        hb.AddConn(inlink.GetTarget(0), hb.GetInput(0).GetConn())
        hb.RemoveInput(0)
    }
    print("hello\n")
    hb
}

func InfiniteWaveform(value : Int64, width!: Int64, name!: String = "", signed!: Bool = false){
    let f = CreateInfiniteWaveform(value, width: width, name: name, signed: signed)
    f.ToGraph()
}



func PrependHead(value : Int64, hb : HypBuilder, signed!: Bool = false){
    Debug("PrependHead", "Prepending value ${value} to the head of this circuit")
    let width = hb.GetN()
    let v = CreateValueFromInt(value, width: width, signed: signed)
    hb.AddNewGraph(v)
    for(i in 0..width){
        let value = v.GetOutput(i).GetLeftEdge()
        let join = hb.CreateEdge(JOIN)
        let delay = hb.CreateEdge(DELAY(1))
        // Connect the value to the join
        hb.AddConn(value.GetTarget(0), join.GetSource(0))
        // Connect the output of f to the new delay
        hb.AddConn(hb.GetOutput(i).GetConn(), delay.GetSource(0))
        // Connect the delay to the join
        hb.AddConn(delay.GetTarget(0), join.GetSource(1))
        // Connect the join to the outputs
        hb.AddConn(join.GetTarget(0), hb.GetOutput(i))
        // Remove the original output inherited from f
        hb.RemoveOutput(width)
    }
    print("Hello\n")
    hb
}

/**
 * Create a new spec to be used for links
 * @param width The width of this spec
 * @param name The name to associate with this spec
 * @return The new link spec
 */
external func NewSpec(width!: Int64 = 1, name!: String = ""){
    if(width < 1){
        throw NegativeWireException("NewSpec")
    }
    LinkSpec(name, width)
}
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
external func Delay(dur!: Int64 = 1, width!: Int64 = 1, label!: String = "", elem!: Int64 = 0, name!: String = "",  input!: Option<Hypergraph> = None<Hypergraph>) : Hypergraph { 
    Debug("Delay", "Creating delay of duration ${dur} and width ${width}")
    if(width < 1){
        throw NegativeWireException("Delay")
    }
    let hb = HypBuilder(width, width, label, elem)
    for(i in 0..width){
        hb.CreateEdge(DELAY(dur), [hb.GetInputs()[i]], [hb.GetOutputs()[i]])
    }
    let res = hb.ToGraph(name)
    match(input) {
        case Some(f) => Seq(f, res)
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
external func Register(width!: Int64, initial!: Int64, duration!: Int64 = 1, label!: String = "", name!: String = "", input!: Option<Hypergraph> = None<Hypergraph>) : Hypergraph {
    Debug("Register", "Making regist of width ${width} with initial value ${initial} and duration ${duration}")
    match(input){
    case Some(f) =>
            if(f.GetN() != width){
                  throw BadInputGraphException("Register", "input", width, f.GetName(), f.GetN())
            }
        case $None => ()
    } 
    if(duration < 0){
        throw NegativeDurationException("Register", duration)
    }
    let hb = HypBuilder(width, width, label, 0)
    // Convert the initial value into binary
    let initialBin = DecToBin(width, initial, true)
    // We need to join the ith bit of this number with a delay
    for(i in 0..width){
        // Value for the ith bit of the initial value
        let value = hb.CreateEdge(VALUE(if(initialBin[i]) { TRUE } else { FALSE }))
        // Delay
        let delay = hb.CreateEdge(DELAY(duration), [hb.GetInputs()[i]])
        // Join the value and the delay
        let join = hb.CreateEdge(JOIN, [value.GetTarget(0), delay.GetTarget(0)], [hb.GetOutputs()[i]])
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
external func InLink(spec!: LinkSpec, label!: String = "", name!:String = "") : Hypergraph { 
    Debug("InLink", "Creating in link for spec ${spec.name}")
    let wires = ArrayList<Wire>(spec.width, {i : Int64 => NewWire(label, i)})
    OpMToN(INLINK(spec), wires: wires, name: name) 
}
/**
 * Create a fixpoint: a construct that feeds its outputs back to some in link while also outputting them
 * @param spec   The link spec for the loop
 * @return The fixpoint
 */
external func CreateFeedback(spec: LinkSpec, label!: String = "") : HypBuilder {
    let hb = HypBuilder(spec.width, spec.width, label)
    let link = hb.CreateEdge(OUTLINK(spec))
    for(i in 0..spec.width){
        let fork = hb.CreateEdge(FORK, [hb.GetInputs()[i]], [link.sources[i], hb.GetOutputs()[i]])
    }
    hb
}
/**
 * Create a fixpoint: a construct that feeds its outputs back to some in link while also outputting them
 * @param spec   The link spec for the loop
 * @param output The name to assign the output bus
 * @param name   The name to give this circuit
 * @return The fixpoint
 */
external func Feedback(spec!: LinkSpec, label!: String = "", name!: String = "", input!: Option<Hypergraph> = None<Hypergraph>){
    Debug("Feedback", "Creating feedback to spec ${spec.name}")
    match(input){
        case Some(f) =>
            if(f.GetN() != spec.width){
                throw TypeMismatchException("Feedback", f, spec.width)
            }
        case $None => ()
    }
    let res = CreateFeedback(spec, label: label).ToGraph()
    match(input){
        case Some(f) => Seq(f, res)
        case $None   => res
    }
}

external func FeedbackReg(spec!: LinkSpec, label!: String = "", name!: String = "", input!: Option<Hypergraph> = None<Hypergraph>, initial!: Int64, signed!: Bool = false){
    Debug("FeedbackReg", "Creating feedback to spec ${spec.name} with register")
    match(input){
        case Some(f) =>
            if(f.GetN() != spec.width){
                throw TypeMismatchException("Feedback", f, spec.width)
            }
        case $None => ()
    }
    let fb = CreateFeedback(spec, label: label)
    let v = CreateValueFromInt(initial, width: spec.width, signed: signed)
    fb.AddNewGraph(v)

    for(i in 0..spec.width){
        let fork = fb.GetOutput(i).GetLeftEdge()
        let join = fb.CreateEdge(JOIN)
        let delay = fb.CreateEdge(DELAY(1))
        // Connect the join to the outlink
        fb.AddConn(join.GetTarget(0), fork.GetTarget(0).GetConn())
        // Connect the target of the value to the lhs of the join
        fb.AddConn(v.GetOutput(i).GetConn(), join.GetSource(0))
        // Connect the lhs of the fork to the delay
        fb.AddConn(fork.GetTarget(0), delay.GetSource(0))
        // Connect the target of the delay to the rhs of the join
        fb.AddConn(delay.GetTarget(0), join.GetSource(1))
        fb.RemoveOutput(spec.width)
    }

    let res = fb.ToGraph()

    match(input){
        case Some(f) => Seq(f, res)
        case $None   => res
    }
}