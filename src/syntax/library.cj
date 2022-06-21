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

public func BUF(i : Int64) : Label {
    GATE(GateSpecification("BUF(${i})", 1, i))
}
public func NOT(i : Int64) : Label {
    GATE(GateSpecification("NOT(${i})", 1, i))
}

/**
 * Binary gates
 */

public func AND(i : Int64) : Label {
    GATE(GateSpecification("AND(${i})", 2, i))
}
public func OR(i : Int64) : Label {
    GATE(GateSpecification("OR(${i})", 2, i))
}
public func NAND(i : Int64) : Label {
    GATE(GateSpecification("NAND(${i})", 2, i))
}
public func NOR(i : Int64) : Label {
    GATE(GateSpecification("NOR(${i})", 2, i))
}
public func XOR(i : Int64) : Label {
    GATE(GateSpecification("XOR(${i})", 2, i))
}
public func XNOR(i : Int64) : Label {
    GATE(GateSpecification("XNOR(${i})", 2, i))
}

/**
 * Ternary gates
 */
 
public func MUX(i : Int64) : Label {
    GATE(GateSpecification("MUX(${i})", [1,i,i], i))
}