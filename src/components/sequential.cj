package components

public func Delay (duration : Int64, input: Wire) : Wire {
    let width = input.GetVertex().GetWidth()
    let edge = Edge(DELAY(duration, width), [input], [width])
    Wire(edge.GetTarget(0))
}

public func SimpleRegister(initial : Int64, signed : Bool, input : Wire) : Wire {
    let width = input.GetVertex().GetWidth()
    let value = if (signed) {
        UnsignedValueFromInt(initial, width)
    } else {
        SignedValueFromInt(initial, width)
    }
    let delay = Delay(1, input)
    let edge = Edge(JOIN(width), [value, delay], [width])
    Wire(edge.GetTarget(0))
}

public func Feedback(outgoing : Wire, incoming : Wire) : Unit {
    if (incoming.GetVertex().GetInEdges().size() != 0) {
        throw NotDanglingWireException("Feedback", incoming)
    }
    MergeVertices(outgoing, incoming)
}