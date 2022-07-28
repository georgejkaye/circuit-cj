# `graphs`

Files specifying hypergraphs and friends, used to model circuits.

## [`assertions.cj`](assertions.cj)

Contains assertions specific to graphs.

## [`dot.cj`](dot.cj)

Contains functions for generating dot graphs representing hypergraphs.

## [`edge.cj`](edge.cj)

Contains the definition of the `Edge` class.
A (hyper)`Edge` represents a circuit component, and can have arbitrarily many (but fixed) `Vertex` objects as sources and targets.

## [`exceptions.cj`](exceptions.cj)

Contains exceptions specific to graphs.

## [`hypergraph.cj`](hypergraph.cj)

Contains the definition of the `Hypergraph` class.
A `Hypergraph` is a model of a circuit: it is constructed from `Vertex` and `Edge` objects.

## [`identifiable.cj`](identifiable.cj)

Contains interfaces for elements with unique ids.

## [`interfaced.cj`](interfaced.cj)

Contains the definition of the `InterfacedHypergraph` class.
An `InterfacedHypergraph` is a `Hypergraph` with some specified input and output vertices.

## [`operations.cj`](operations.cj)

Contains functions for composition operations on `InterfacedHypergraph` objects.

## [`vertex.cj`](vertex.cj)

Contains the definition of the `Vertex` class.
A `Vertex` represents a wire in circuits.
