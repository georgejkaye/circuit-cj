package components

public func Delay (duration : Int64, input: Wire) : Wire {
    let width = input.GetWidth()
    MakeEdge(
        DELAY(duration, width),
        [input],
        [width],
        None
    )[0]
}

public func SimpleRegister(initial! : Int64, signed! : Bool, input! : Wire) : Wire {
    let width = input.GetWidth()
    let value = if (signed) {
        SignedValueFromInt(initial, width: width)
    } else {
        UnsignedValueFromInt(initial, width: width)
    }
    SimpleRegisterWithInitial(value, input)
}

func SimpleRegisterWithInitial(initial: Wire, input : Wire){
    let width = initial.GetWidth()
    let delay = Delay(1, input)
    MakeEdge(
        JOIN(width),
        [initial, delay],
        [width],
        None
    )[0]
}

public func Feedback(outgoing : Wire, incoming : Wire) : Unit {
    if (incoming.GetVertex().GetInEdges().size() != 0) {
        throw NotDanglingWireException("Feedback", incoming)
    }
    let width = outgoing.GetWidth()
    if (width != incoming.GetWidth()){
        throw IncompatibleWidthException("Feedback", incoming, width)
    }
    MergeWires(outgoing, incoming)
}

public func DelayedFeedback(outgoing : Wire, incoming : Wire) : Unit {
    let delay = Delay(1, outgoing)
    Feedback(delay, incoming)
}

public func InfiniteWaveform(initial : Wire) {
    let input = MakeWire(initial.GetWidth())
    let reg = SimpleRegisterWithInitial(initial, input)
    Feedback(reg, input)
    reg
}

public func InfiniteWaveform(value : Value) : Wire {
    InfiniteWaveform(Signal(value))
}