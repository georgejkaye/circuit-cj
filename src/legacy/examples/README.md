# `examples` package

This package contains examples of what one can do with the system.
Currently there aren't many but hopefully this can change in time!
These examples will also need to be documented.

## Examples

### [`accumulator.cj`](accumulator.cj)

A slightly more involved example, showing how delay and feedback can be implemented.

### [`alu.cj`](alu.cj)

A simple ALU for arbitrary width inputs that can perform two operations: addition and AND.

### [`cpu.cj`](cpu.cj)

A simple CPU to give a very involved example of circuit design.

> NOTE: This example compiles but does not run.
> Modifying the code so it can run is left as an exercise.

### [`cyclic-combinational.cj`](cyclic-combinational.cj)

A *cyclic combinational* circuit, i.e. a circuit that has non-delay-guarded feedback loops but is still a valid combinational circuit.
The feedback loops act as a way of sharing resources.

### [`fibonacci.cj`](fibonacci.cj)

A classic example of recursion, a circuit to compute the nth fibonacci number.

### [`half-adder.cj`](half-adder.cj)

A very basic example: a half adder.
Defined in combinator style and functional style, to illustrate the differences between them.

### [`serial-multiplier.cj`](serial-multiplier.cj)

A more complex example, combining lots of features such as registers, feedback, and parameterising circuits.

### [`sorting-network.cj`](sorting-network.cj)

Another example of how recursion can be used to create a sorting network for an arbitrary amount of inputs.
