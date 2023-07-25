Accumulator
===========

This section will detail how to specify a simple accumulator circuit.

Specifying the circuit
----------------------

For pedagogical purposes, we will specify all of the components in the
accumulator from scratch.
However, some of these components already exist as ready-made subcircuits in the
standard library.

Full adder
**********

.. code-block:: scala

    public func MakeFullAdder() : BelnapCircuit {
        let inputXor = XorGate(a, b)
        let carryXor = XorGate(inputXor, cin)
        let carryAnd = AndGate(inputXor, cin)
        let inputAnd = AndGate(a, b)
        let carryOr = OrGate(carryAnd, inputAnd)
        MakeSubcircuit(
            [InterfaceWire(a, "A"), InterfaceWire(b, "B"), InterfaceWire(cin, "Cin")],
            [InterfaceWire(carryXor, "S"), InterfaceWire(carryOr, "Cout")],
            "full_adder"
        )
    }

Ripple adder
************

We then apply the ``BitwiseRippleMap`` construction to thread an accumulator
through multiple full adders.

.. code-block:: scala

    public func MakeRippleAdder(width : Int64) : BelnapCircuit {
        let a = sig.UseWire(width)
        let b = sig.UseWire(width)
        let cin = sig.UseWire(1)
        let (sum, carry) = BitwiseRippleMap(
            { acc : Array<BelnapWire>, cur : Array<BelnapWire> =>
                UseSubcircuit(
                    MakeFullAdder(),
                    [cur[0], cur[1], acc[0]]
                ),
                [cin],
                [a, b]
            }
        MakeSubcircuit(
            [InterfaceWire(a, "A"), InterfaceWire(b, "B"), InterfaceWire(cin, "Cin")],
            [InterfaceWire(sum, "S"), InterfaceWire(carry, "Cout")],
            "ripple_adder"
        )
    }

Accumulator
***********

The accumulator combines the ripple adder with a delay-guarded feedback loop.

.. code-block:: scala

    public func Accumulator(width!: Int64, initial!: Int64) : BelnapCircuit {
        let input = sig.UseWire(width)
        let prev = sig.UseWire(width)
        let zero = sig.UseInfiniteWaveform([Signal([FALSE])])
        let (sum, carry) = UseSubcircuit_2(
            MakeRippleAdder(width),
            [prev, input, zero]
        )
        RegisterGuardedFeedback(prev, initial: initial, signed: false, input: sum)
        MakeSubcircuit(
            [InterfaceWire(input, "A")],
            [InterfaceWire(sum, "S")],
            "accumulator"
        )
    }

Let's examine each line in turn.

.. code-block:: scala

    let input = sig.UseWire(width)

We use a wire that will serve as the input to our circuit.
This wire is of the width provided as an argument to the function.

.. code-block:: scala

    let prev = sig.UseWire(width)

We also create a wire that will carry the sum from the previous cycle.
This isn't connected to anything yet, because we haven't defined the components
it will rely on!

.. code-block:: scala

    let zero = sig.UseInfiniteWaveform([Signal([FALSE])])

To use our ripple adder, we need to pass it a carry in value.
Since we are computing the sum from scratch, this will always be zero, and as
such we create an infinite waveform that always produces zero (false).

.. code-block:: scala

    let (sum, carry) = UseSubcircuit_2(
        MakeRippleAdder(width),
        [prev, input, zero]
    )

Now we can use the ripple adder that we defined earlier.
We choose `UseSubcircuit_2` since we know that the circuit has two output wires:
this means we can pattern match on them.

.. code-block:: scala

    RegisterGuardedFeedback(sum, prev, initial: initial, signed: false, input: sum)

We need to feedback the new sum to the `prev` wire we created earlier.
However, since we don't want the feedback to occur until the next cycle, we
store it in a register first.
We use the provided `initial` parameter as its initial value.
If we didn't store it in a register, the circuit would still compile, but the
behaviour would be different: what would the first value of `prev` be?

.. code-block:: scala

    MakeSubcircuit(
        [InterfaceWire(input, "A")],
        [InterfaceWire(sum, "S")],
        "accumulator"
    )

Finally we need to wrap the whole thing in another subcircuit.
And that's it!
We now have an accumulator subcircuit that can used whenever we feel like it.

By using `WriteDotToFile` we can generate graphs depicting our circuit.

.. image:: imgs/accumulator-1.svg

.. image:: imgs/accumulator-2.svg

.. image:: imgs/accumulator-3.svg