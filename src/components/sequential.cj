package components

public func Delay (duration : Int64, input: WireEnd) : WireEnd {
    let width = input.GetWidth()
    let edge = Edge(DELAY(duration, width), [input.GetVertex()], [width])
    WireEnd(edge.GetTarget(0))
}

public func SimpleRegister(initial! : Int64, signed! : Bool, input! : WireEnd) : WireEnd {
    let width = input.GetWidth()
    let value = if (signed) {
        SignedValueFromInt(initial, width: width)
    } else {
        UnsignedValueFromInt(initial, width: width)
    }
    SimpleRegisterWithInitial(value, input)
}

func SimpleRegisterWithInitial(initial: WireEnd, input : WireEnd){
    let width = initial.GetWidth()
    let delay = Delay(1, input)
    let edge = Edge(JOIN(width), [initial.GetVertex(), delay.GetVertex()], [width])
    WireEnd(edge.GetTarget(0))
}

public func Feedback(outgoing : WireEnd, incoming : WireEnd) : Unit {
    if (incoming.GetVertex().GetInEdges().size() != 0) {
        throw NotDanglingWireException("Feedback", incoming)
    }
    let width = outgoing.GetWidth()
    if (width != incoming.GetWidth()){
        throw IncompatibleWidthException("Feedback", incoming, width)
    }
    MergeWires(outgoing, incoming)
}

public func DelayedFeedback(outgoing : WireEnd, incoming : WireEnd) : Unit {
    let delay = Delay(1, outgoing)
    Feedback(delay, incoming)
}

public func InfiniteWaveform(initial : WireEnd) {
    let input = Wire(initial.GetWidth())
    let reg = SimpleRegisterWithInitial(initial, input)
    Feedback(reg, input)
    reg
}

public func InfiniteWaveform(value : Value) : WireEnd {
    InfiniteWaveform(Signal(value))
}