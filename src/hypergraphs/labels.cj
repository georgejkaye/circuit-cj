package hypergraphs

import core.*

/**
 * Structural generators
 */

external let FORK : MorphismKind = STRUCTURAL(Label("≺", 1, 2))
external let JOIN : MorphismKind = STRUCTURAL(Label("≻", 2, 1))
external let STUB : MorphismKind = STRUCTURAL(Label("~", 1, 0))

/**
 * Unary gates
 */

external let BUF : MorphismKind = GATE(Label("BUF", 1, 1))
external let NOT : MorphismKind = GATE(Label("NOT", 1, 1))

/**
 * Binary gates
 */

external let AND  : MorphismKind = GATE(Label("AND", 2, 1))
external let OR   : MorphismKind = GATE(Label("OR", 2, 1))
external let NAND : MorphismKind = GATE(Label("NAND", 2, 1))
external let NOR  : MorphismKind = GATE(Label("NOR", 2, 1))
external let XOR  : MorphismKind = GATE(Label("XOR", 2, 1))
external let XNOR : MorphismKind = GATE(Label("XNOR", 2, 1))