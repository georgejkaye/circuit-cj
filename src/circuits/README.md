# `circuits` package

## Internal files

These files contain definitions used 'behind the scenes' to support the system.

### [`atoms.cj`](atoms.cj)

Contains definitions for the atoms that make up hypergraphs.

### [`builder.cj`](builder.cj)

Contains the definition of `HypBuilder`, a class for constructing hypergraphs that may not necessarily be well-formed.

### [`buses.cj`](buses.cj)

Contains definitions of buses and wires, which are used to label source vertices.
These buses form the backbone of how users can refer to and extract specific parts of circuits.

### [`exceptions.cj`](exceptions.cj)

Contains exceptions for this package.

### [`generators.cj`](generators.cj)

Contains definition of generators, which are used to label edges in hypergraphs.

### [`reduce.cj`](reduce.cj)

Contains functions for applying the operational semantics to hypergraphs and reducing them to a simpler for.

### [`traverse.cj`](traverse.cj)

Contains functions for traversing hypergraphs in different ways.

## External files

These files contain definitions exported for the user to create circuits with.

### [`arithmetic.cj`](arithmetic.cj)

This file contains definitions for arithmetic circuits.

* `HalfAdder`
* `FullAdder`
* `Adder` an n-bit adder
* `Plus` an n-bit adder with the carry initialised to zero

### [`bits.cj`](bits.cj)

Contains functions for manipulating individual bits in buses of values.

* `Msb`
* `Lsb`
* `Msbs`
* `Lsbs`

### [`dot.cj`](dot.cj)

Contains functions for translating circuits into dot graphs.

* `DotGraph` whether or not to resolve links can be toggled
* `WriteDotToFile`

### [`gates.cj`](gates.cj)

Contains functions to generate numerous gates and structures.

* `Bottom` A value representing a disconnected wire
* `Top` A value representing a short circuit (i.e. the join of True and False)
* `True`
* `False`
* `Fork`
* `Join`
* `Stub`
* `Copy` Fork buses of arbitrary width
* `Erase` Stub buses of arbitrary width
* `Merge` Join buses of arbitrary width
* `Init` Create buses of disconnected wires of arbitrary width
* `NotGate`
* `AndGate`
* `OrGate`
* `XorGate`
* `NandGate`
* `NorGate`
* `XnorGate`
* `Mux`

### [`hypergraph.cj`](hypergraph.cj)

The definition of hypergraphs.

* `Hypergraph::Clone` Create a deep copy of this graph will new atom names
* `Hypergraph::Get` Extract an output or bus from the graph, stubbing all other outputs
  * Also `[]`
* `Hypergraph::Drop` Stub an output of the graph
* `Hypergraph::Seq` Compose this hypergraph with another in sequence
  * Also `*`
* `Hypergraph::Par` Compose this hypergraph with another in paralleL
  * Also `+`
* `Hypergraph::Tr` Trace this hypergraph with a given number of wires

### [`interfaces.cj`](interfaces.cj)

Contains functions for manipulating and creating interfaces for circuits.

* `Input` Create an input bus with a label
* `Concat` Concatenate the outputs of two graphs together, accounting for shared wires within them

### [`operations.cj`](operations.cj)

Contains functions details operations on hypergraphs.

* `Seq` Compose two hypergraphs in sequence
* `Identity` Create an identity hypergraph
* `Par` Compose two hypergraphs in parallel
* `Empty` Create an empty hypergraph (identity on 0)
* `Symmetry` Create a hypergraph that swaps some wires
* `Trace` Trace a hypergraph with a number of wires
* `Get` Extract an output or bus from a hypergraph, stubbing all other outputs
* `Drop` Stub an output of a hypergraph

### [`sequential.cj`](sequential.cj)

Contains functions to create sequential circuits with delays and feedback.

* `NewLink` Create a new Link for tagging feedback with
* `Delay` Create a delay construct
* `Register` Create a register with some initial value, that delays all inputs for some cycles
* `OutLink` Create an outlink that takes in signals with the intention of spitting them out somewhere else in the graph
* `InLink` Create an inlink that spits some signals into the graph
* `Feedback` Create a construct that forks its inputs, sends one set to be fed back, and outputs the other

### [`values.cj`](values.cj)

Contains functionas for creating values: hypergraphs with no inputs. Generally these correspond to a number represented in binary.

* `SignedValueFromInt`
* `UnsignedValueFromInt`
* `Zero` Creates a zero value for a given width
* `UnsignedExtend` Add an extra zero bit at the front of a value