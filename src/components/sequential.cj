package components

public func Delay (duration : Int64, input: Vertex) : Vertex {
    let width = input.GetWidth()
    let edge = Edge(DELAY(duration, width), [input], [width])
    edge.GetTarget(0)
}

public func SimpleRegister(initial : Int64, signed : Bool, input : Vertex) : Vertex {
    let width = input.GetWidth()
    let value = if (signed) {
        UnsignedValueFromInt(initial, width)
    } else {
        SignedValueFromInt(initial, width)
    }
    let delay = Delay(1, input)
    let edge = Edge(JOIN(width), [value, delay], [width])
    edge.GetTarget(0)
}