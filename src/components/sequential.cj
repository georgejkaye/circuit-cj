package components

public func Delay (duration : Int64, input: WireEnd) : WireEnd {
    let width = input.GetVertex().GetWidth()
    let edge = Edge(DELAY(duration, width), [input.GetVertex()], [width])
    WireEnd(edge.GetTarget(0))
}

public func SimpleRegister(initial! : Int64, signed! : Bool, input! : WireEnd) : WireEnd {
    let width = input.GetVertex().GetWidth()
    let value = if (signed) {
        SignedValueFromInt(initial, width)
    } else {
        UnsignedValueFromInt(initial, width)
    }
    let delay = Delay(1, input)
    let edge = Edge(JOIN(width), [value.GetVertex(), delay.GetVertex()], [width])
    WireEnd(edge.GetTarget(0))
}

public func Feedback(outgoing : WireEnd, incoming : WireEnd) : Unit {
    if (incoming.GetVertex().GetInEdges().size() != 0) {
        throw NotDanglingWireException("Feedback", incoming)
    }
    MergeVertices(outgoing, incoming)
}