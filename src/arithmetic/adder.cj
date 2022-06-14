package arithmetic

import components.*
import syntax.*

public func Adder(a : WireEnd, b : WireEnd) : WireEnd {
    if (a.GetVertex().GetWidth() != b.GetVertex().GetWidth()) {
        throw InputsNotSameWidthException("Adder", a, b)
    }
    let width = a.GetVertex().GetWidth()
    let adderSpec = Specification("adder", [width, width], [width])
    BlackBox(adderSpec, [a, b])[0]
}