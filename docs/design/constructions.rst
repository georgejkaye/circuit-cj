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

.. note::
    Operations have *types*: the widths of their input and output wires.
    For example, a 4-bit ripple adder has type ``[4,4] -> [4,1]``.
    We write ``[n^x]`` for a list of length ``x`` containing only ``n``.

Map
---

Apply multiple copies of an operation in parallel.

.. code-block:: scala

    let bb = sig.AddBlackbox("f", [Port(2), Port(4)], [Port(1), Port(3)])
    let f = MakeBlackbox(bb)
    let bmapf = MakeMap(f, 3)


.. image:: imgs/constructions/map.svg


Bitwise map
-----------

Apply multiple copies of an operation in parallel for each bit of a wire.
This corresponds to the functional construction ``fold`` (also known as
``reduce``).

.. code-block:: scala

    let bb = sig.AddBlackbox("f", [Port(1), Port(1)], [Port(1)])
    let f = MakeBlackbox(bb)
    let bmapf = MakeBitwiseMap(f, 3)


.. image:: imgs/constructions/bitwise-map.svg



Bitwise logic gates
*******************

Applying logic gates to wires of arbitrary width bitwise is very common.
In the Belnap signature, the logic gate functions are overloaded so that it is
easy to define them.

.. code-block:: scala

    // Create a bitwise AND gate
    let a = sig.UseWire(2)
    let b = sig.UseWire(2)
    // AND(a[0], b[0]) ++ AND(a[1], b[1])
    UseAnd(a, b)

At the highest level this just appears to be a normal ``AND`` gate:

.. image:: imgs/constructions/bitwise-and-0.svg

If we open up the ``AND2_2`` box we can see what's going on inside:

.. image:: imgs/constructions/bitwise-and-1.svg

.. warning::
    Although the inputs to bitwise logic gates can be of any width, each input
    wire must still be the *same* width!

Ripple
------

Starting with some initial value, apply an operation to each input wire and
the result of the previous computation in sequence.
This corresponds to the functional construction ``fold``.



If there is no special initial value, the first array of wires in the inputs can
be used instead:

.. code-block:: scala

    func Ripple(
        // (acc, cur) -> acc
        f :  (Array<Wire>, Array<Wire) -> Array<Wire>,
        wss : Array<Array<Wire>>
    ) : Array<Wire>

Ripple logic gates
******************

Ripple constructions occur when we want to apply a logic gate to an arbitrary
number of inputs.
In the Belnap signature, the logic gate functions are also overloaded for this
purpose, which can be specified by providing an *array* of input wires.

.. code-block:: scala

    // Create a ripple AND gate
    let a = MakeWire(1)
    let b = MakeWire(1)
    let c = MakeWire(1)
    // AND(AND(a, b), c)
    And([a, b, c])

As with bitwise gates, this is displayed as a single operation on a high level:

.. image:: imgs/constructions/ripple-and-1.svg

...but we can look inside it and find out what's going on:

.. image:: imgs/constructions/ripple-and-2.svg

Bitwise gates can also be rippled, so a ripple gate that processes arbitrary
width wires are also definable.

.. warning::
    Again, make sure that the inputs are still the same width.

Bitwise ripple
---------------

Occasionally we want to perform a ripple as specified in the previous section,
but rather than using multiple arrays of input wires, we want to perform it over
the bits in the wires themselves.
This is known as a *bitwise ripple*.

.. code-block:: scala

    func BitwiseRipple(
        // (acc, cur) -> acc
        f :  (Array<Wire>, Array<Wire) -> Array<Wire>
        ws : Array<Wire>
    ) : Array<Wire>

Internal ripple logic gates
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

The ``Map`` and ``Ripple`` constructions are actually generalisat

It is sometimes useful to extend the ``Ripple`` construction so that each
iteration of the circuit can produce an output in addition to the threaded
accumulator.
One such example is a ripple adder.
In a ``BitwiseRipple``, these outputs will be collected and combined into a
single wire for output.

.. code-block:: scala

    func RippleMap(
        // (acc, cur) -> (out, acc)
        f : (Array<Wire>, Array<Wire) -> (Array<Wire>, Array<Wire>)
        initial : Array<Wire>,
        wss : Array<Array<Wire>
    ) : (Array<Array<Wire>>, Array<Wire>)

Ripple map logic gates
***********************

A classic example of a ripple map circuit is a *ripple adder*.

.. code-block:: scala

    let fullAdder = MakeFullAdder()
    // The outputs of the full adder are (sum (output), carry (acc))
    let rippleAdder = MakeRippleMap(fullAdder, 1, 4)

.. image:: imgs/constructions/ripple-map-adder-0.svg

.. image:: imgs/constructions/ripple-map-adder-1.svg