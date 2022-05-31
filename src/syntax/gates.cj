/**
 * gates.cj
 *
 * This file contains some predefined gates
 */

package syntax

/**
 * Unary gates
 */

let BUF : Label = GATE(Interface("BUF", 1, 1))
let NOT : Label = GATE(Interface("NOT", 1, 1))

/**
 * Binary gates
 */

let AND : Label = GATE(Interface("AND", 2, 1))
let OR : Label = GATE(Interface("OR", 2, 1))
let NAND : Label = GATE(Interface("NAND", 2, 1))
let NOR  : Label = GATE(Interface("NOR", 2, 1))
let XOR  : Label = GATE(Interface("XOR", 2, 1))
let XNOR : Label = GATE(Interface("XNOR", 2, 1))

/**
 * Ternary gates
 */
 
let MUX : Label = GATE(Interface("mux", 3, 1))