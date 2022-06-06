/**
 * gates.cj
 *
 * This file contains some predefined gates
 */

package syntax

/**
 * Unary gates
 */

public let BUF : Label = GATE(GateSpecification("BUF", 1))
public let NOT : Label = GATE(GateSpecification("NOT", 1))

/**
 * Binary gates
 */

public let AND  : Label = GATE(GateSpecification("AND", 2))
public let OR   : Label = GATE(GateSpecification("OR", 2))
public let NAND : Label = GATE(GateSpecification("NAND", 2))
public let NOR  : Label = GATE(GateSpecification("NOR", 2))
public let XOR  : Label = GATE(GateSpecification("XOR", 2))
public let XNOR : Label = GATE(GateSpecification("XNOR", 2))

/**
 * Ternary gates
 */
 
public let MUX : Label = GATE(GateSpecification("mux", 3))