package hypergraphs

import hypergraphs.Label

/**
 * Structural generators
 */

external let FORK : Label = Label("≺", 2, 1)
external let JOIN : Label = Label("≻", 2, 1)
external let STUB : Label = Label("~", 2, 1)

/**
 * Unary gates
 */

external let BUF : Label = Label("BUF", 1, 1)
external let NOT : Label = Label("NOT", 1, 1)

/**
 * Binary gates
 */

external let AND : Label = Label("AND", 2, 1)
external let OR : Label = Label("OR", 2, 1)
external let NAND : Label = Label("NAND", 2, 1)
external let NOR : Label = Label("NOR", 2, 1)
external let XOR : Label = Label("XOR", 2, 1)
external let XNOR : Label = Label("XNOR", 2, 1)