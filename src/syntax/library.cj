/**
 * gates.cj
 *
 * This file contains some predefined gates
 */

package syntax

/**
 * Signals
 */

public let BOTTOM : Label = VALUE([Bottom], false)
public let FALSE : Label = VALUE([False], false)
public let TRUE : Label = VALUE([True], false)
public let TOP : Label = VALUE([Top], false)

/**
 * Unary gates
 */

public func BUF(m : Int64, w : Int64) : Label {
    GATE(GateSpecification("BUF(${m},${w})", 1, w))
}
public func NOT(m : Int64, w : Int64) : Label {
    GATE(GateSpecification("NOT(${m},${w})", 1, w))
}

/**
 * Binary gates
 *
 * Each gate has two parameters:
 * - how many wires it takes as inputs
 * - the width of each wire
 */

public func AND(m : Int64, w : Int64) : Label {
    GATE(GateSpecification("AND(${m},${w})", m, w))
}
public func OR(m : Int64, w : Int64) : Label {
    GATE(GateSpecification("OR(${m},${w})", m, w))
}
public func NAND(m : Int64, w : Int64) : Label {
    GATE(GateSpecification("NAND(${m},${w})", m, w))
}
public func NOR(m : Int64, w : Int64) : Label {
    GATE(GateSpecification("NOR(${m},${w})", m, w))
}
public func XOR(m : Int64, w : Int64) : Label {
    GATE(GateSpecification("XOR(${m},${w})", m, w))
}
public func XNOR(m : Int64, w : Int64) : Label {
    GATE(GateSpecification("XNOR(${m},${w})", m, w))
}

/**
 * Ternary gates
 */
 
public func MUX(w : Int64) : Label {
    GATE(GateSpecification("MUX(${w})", [1,w,w], w))
}