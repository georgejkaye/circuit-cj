# `syntax`

Files specifying the syntax of sequential circuits.

## [`label.cj`](label.cj)

Contains the definition of the `Label` enum.
Effectively, a `Label` is a generator in the free categorical sense.

## [`library.cj`](library.cj)

Contains specifications for the predefined `Primitive`, `Composite` and `Blackbox` classes of generators.

## [`port.cj`](port.cj)

Contains the definition of the `Port` record.
A `Port` is a width with an optional name: these specify the individual inputs and outputs of generators.

## [`value.cj`](value.cj)

Contains the definition of the `Value` enum.
A `Value` is one of the signals that flow in circuit wires.
