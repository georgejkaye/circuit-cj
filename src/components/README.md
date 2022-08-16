# `components`

Files specifying components that can be used in circuits.

## ['assertions.cj`](assertions.cj)

Contains assertions specific to components.

## [`construction.cj`](construction.cj)

Contains functions for constructing bigger circuits.
In particular, contains `Bitwise` for constructing circuits that apply the same operation to each bit of a wire, and `Ripple` for constructing circuits that 'ripples' an operation across multiple inputs.

## [`library.cj`](library.cj)

Contains common components and composite logic gates.

## [`primitive.cj`](primitive.cj)

Contains functions for manipulating primitives, the basic logic gates that circuits are constructed from.

## [`sequential.cj`](sequential.cj)

Contains functions for adding _sequential_ components to circuits: delay and feedback.

## [`subcircuit.cj`](subcircuit.cj)

Contains functions for dealing with _subcircuits_.
One can `Make` a subcircuit given some input and output wires, returning an `InterfacedHypergraph`, or one can `Use` a subcircuit given some input wires, returning an array of `Wire`s.

## [`values.cj`](values.cj)

Contains functions for manipulating _values_.
A value is a collection of `Bottom`, `True`, `False` and `Top` signals that represents something that flows through a wire.

## [`wires.cj`](wires.cj)

Contains the definition of the `Wire` class.
A `Wire` is a mutable pointer to a `Vertex`: this is useful since a vertex may become merged with another and discarded.
