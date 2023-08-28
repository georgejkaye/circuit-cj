Constructions
=============

We have seen how we can use subcircuits as a tool to replicate behaviour in
multiple parts of a circuit.
But always building subcircuits can still be tedious, or even restrictive.
In particular, how can we *parameterise* these subcircuits, so that one function
can create circuits for an arbitrary number of inputs or wire widths?
Fortunately, CircuitCJ provides some higher-orer constructions that can be used
to build such subcircuits.
The functional programmer may recognise them!

Map
---

Apply multiple copies of an operation in parallel.

.. code-block:: scala

    let bb = sig.AddBlackbox("f", [Port(2), Port(4)], [Port(1), Port(3)])
    let f = MakeBlackbox(bb)
    // Map the blackbox three times
    MakeMap(f, numberOfOperations: 3)


.. image:: imgs/constructions/map.svg


Bitwise map
-----------

Apply ``n`` copies of an operation in parallel, where the ``i`` th input of each
operation makes up ``1\n`` the width of the ``i`` th input wire of the circuit.

.. code-block:: scala

    let bb = sig.AddBlackbox("f", [Port(1), Port(1)], [Port(1)])
    let f = MakeBlackbox(bb)
    // Map the blackbox three times
    MakeBitwiseMap(f, numberOfOperations: 3)


.. image:: imgs/constructions/bitwise-map-0.svg

It is also possible to only split some of the input wires bitwise.
For example, this can be useful if a control wire is shared between all the
operations.

.. code-block:: scala

    // Map the blackbox three times, but share the 0th input wire
    MakeBitwiseMap(f, numberOfOperations: 3, sharedInputWires: [0])


.. image:: imgs/constructions/bitwise-map-1.svg



Bitwise logic gates
*******************

Applying logic gates to wires of arbitrary width bitwise is very common.
In the Belnap signature, the logic gate functions are overloaded so that it is
easy to define them.

.. code-block:: scala

    // Use a bitwise AND gate
    let a = sig.UseWire(2)
    let b = sig.UseWire(2)
    // AND(a[0], b[0]) ++ AND(a[1], b[1])
    UseAnd(a, b)

At the highest level this just appears to be a normal ``AND`` gate:

.. image:: imgs/constructions/bitwise-and-0.svg

If we open up the ``AND2_2`` box we can see what's going on inside:

.. image:: imgs/constructions/bitwise-and-1.svg

Another frequent bitwise construction is that of a *multiplexer*, which
illustrates when one may want to share wires rather than split them.

.. code-block:: scala

    // Use a bitwise multiplexer
    let selector = sig.UseWire(1)
    let inputs = sig.UseWires(2, width: 4)
    UseMux(selector: selector, inputs: inputs)

.. image:: imgs/constructions/mux2-4.svg

Ripple
------

Starting with some initial value, apply an operation to each input wire and
the result of the previous computation in sequence.
This corresponds to the functional construction *fold*.

.. code-block:: scala

    // Create a blackbox with an accumulator input (1) and data input (2) that
    // outputs the new accumulator output (0)
    let bb = sig.AddBlackbox("f", [Port(1), Port(2)], [Port(1)])
    let f = MakeBlackbox(bb)
    let ripple = MakeRipple(f, numberOfOperations: 3)

.. image:: imgs/constructions/ripple.svg

Ripple logic gates
******************

Ripple constructions occur when we want to apply a logic gate to an arbitrary
number of inputs.
In the Belnap signature, the logic gate functions are also overloaded for this
purpose, which can be specified by providing an *array* of input wires.

.. code-block:: scala

    // Use a ripple AND gate
    let a = sig.UseWire(1)
    let b = sig.UseWire(1)
    let c = sig.UseWire(1)
    // AND(AND(a, b), c)
    UseAnd([a, b, c])

As with bitwise gates, this is displayed as a single operation on a high level:

.. image:: imgs/constructions/ripple-and-0.svg

...but we can look inside it and find out what's going on:

.. image:: imgs/constructions/ripple-and-1.svg

Of course, this is not limited to logic gates with single-bit inputs; we can
combine the ripple construction with the bitwise map construction above.

.. code-block:: scala

    // Use a ripple bitwise map AND gate
    let a = sig.UseWire(2)
    let b = sig.UseWire(2)
    let c = sig.UseWire(2)
    // AND(AND(a, b), c)
    UseAnd([a, b, c])

.. image:: imgs/constructions/ripple-bitwise-and-0.svg

.. image:: imgs/constructions/ripple-bitwise-and-1.svg

.. image:: imgs/constructions/ripple-bitwise-and-2.svg


Bitwise ripple
---------------

Occasionally we want to perform a ripple as specified in the previous section,
but rather than using multiple arrays of input wires, we want to perform it over
the bits in the wires themselves.
This is known as a *bitwise ripple*.




Bitwise ripple logic gates
***************************

This construction has an interpretation is Belnap logic gates:

.. code-block:: scala

    let a = MakeWire(3)
    // AND(AND(a[0], a[1]), a[2])
    And(a)

.. image:: imgs/constructions/internal-ripple-and-1.svg

.. image:: imgs/constructions/internal-ripple-and-2.svg

Ripple map
----------

The ``Map`` and ``Ripple`` constructions are actually generalisations of a
construction called a ``RippleMap``.


It is sometimes useful to extend the ``Ripple`` construction so that each
iteration of the circuit can produce an output in addition to the threaded
accumulator.
One such example is a ripple adder.
In a ``BitwiseRipple``, these outputs will be collected and combined into a
single wire for output.

.. image:: imgs/constructions/ripple-map.svg

Ripple map logic gates
***********************

A classic example of a ripple map circuit is a *ripple adder*.

.. code-block:: scala

    let fullAdder = MakeFullAdder()
    // The outputs of the full adder are (sum (output), carry (acc))
    let rippleAdder = MakeRippleMap(fullAdder, 1, 4)

.. image:: imgs/constructions/ripple-map-adder-0.svg

.. image:: imgs/constructions/ripple-map-adder-1.svg