Wires and primitives
====================

Circuits are constructed by connecting wires to different components.

Choosing a signature
--------------------

Before we begin, we must choose the *signature*, or gate set, that we are going to use in this project.
Several are provided as part of the standard library: we are going to use [*Belnap's four valued logic*](https://en.wikipedia.org/wiki/Four-valued_logic#Belnap).

.. code-block:: scala

    import signatures.belnap.*
    let sig = belnapSignature

In addition to the standard true and false values, Belnap logic contains a value for *no* signal ('disconnected wire', ``Bottom``), and *both* signals at once ('short circuit', ``Top``).
These additional values are crucial when it comes to *evaluating* circuits.

.. note::
    The causal user does not need to be too concerned over what a signature actually is: only that it specifies the components that can be used in a circuit.
    The interested reader can refer to [Signatures](Advanced/Signatures) for more details.

Making dangling wires
---------------------

Circuits are constructed by connecting ``Wire`` objects to circuit components.
To start building circuits, we must specify some dangling wires.
Wires are parameterised by a ``width``, which determines how many bits flow through each wire.

.. code-block:: scala

    let a = sig.UseWire(1)
    let b = sig.UseWire(8)

In a wire carrying multiple bits, we consider w[0] to be the *least significant bit* and w[n-1] to be the *most significant bit*.

Using wires
-----------

Conventionally, functions starting with ``Use`` return one or more ``Wire`` objects , so they can immediately be passed to other functions.

Splitting wires
---------------

When we have a wire containing multiple bits, we sometimes want to deal with only some of them.
For example, we might want to use the least significant bit as some output flag.
A variety of ``Split`` functions are provided that allow you to split a single wire into multiple wires.

.. code-block:: scala

    let a = sig.UseWire(8)

There are multiple ways we can split a wire:

.. code-block:: scala

    // Split into consituent bits
    let ws = Split(a)

.. image:: imgs/wires-and-primitives/split-1.svg

.. code-block:: scala

    // Split at the first bit
    let (lhs, rhs) = Split(a, 1)

.. image:: imgs/wires-and-primitives/split-2.svg

.. code-block:: scala

    // Split into wires of width 1, 3, 4
    let ws2 = Split(a, [1, 3, 4])

.. image:: imgs/wires-and-primitives/split-3.svg

.. warning::
    When splitting a wire by explicitly setting the wire widths, make sure they sum to the width of the original wire!

Combining wires
---------------

The opposite is also true: it can be more convenient to combine two wires into one, *concatenating* their contents.

.. code-block:: scala

    let a = sig.UseWire(4)
    let b = sig.UseWire(4)
    let c = sig.UseWire(8)

.. code-block:: scala

    // Combine just two wires
    let w1 = Combine(a, b)

.. image:: imgs/wires-and-primitives/combine-1.svg

.. code-block:: scala

    // Combine an arbitrary number of wires
    let w2 = Combine([a, b, c])

.. image:: imgs/wires-and-primitives/combine-2.svg

Primitives
----------

Wires on their own are pretty useless.
To add some actual computation to circuits we need some sort of *logic gates*, or *primitives* as they are known in CircuitCJ.
Each primitive has an associated *arity* and *coarity*: an array of widths that are the inputs and outputs of each primitive.

The set of available primitives is specified in the signature.
For example, the default Belnap signature has primitives ``AND`` (``[2]->[1]``), ``OR`` (``[2]->[1]``) and ``NOT`` (``[1]->[1]``).

To use a logic gate, we must specify the wires that will act as its inputs:

.. code-block:: scala

    let a = sig.UseWire(1)
    let b = sig.UseWire(1)
    let and = UseGate(AND, [a, b])

.. image:: imgs/wires-and-primitives/and.svg

In the Belnap signature we can also specify gates directly.

.. code-block:: scala

    let and = And(a, b)
    let or = Or(a, b)
    let not = Not(a)


Using a gate returns another ``Wire`` that can be used in other gates.
Constructing circuits is therefore as simple as passing the output of each gate to the next one.
If desired, wires can be used multiple times.

.. code-block:: scala

    let a = sig.UseWire(1)
    let b = sig.UseWire(1)
    let and = And(a, b)
    let or = Or(and, b)
    let not = Not(or)

.. image:: imgs/wires-and-primitives/and-or-not.svg

.. note::
    The diagrams in this section have had input and output interfaces, but the eagle-eyed reader may notice we haven't actually specified them yet!
    This will be detailed in the next section.

Black boxes
-----------

A final component we may wish to use in our circuits is a *black box*.
A black box is a component that we know nothing about except its interface.

.. code-block:: scala

    let a = sig.UseWire(2)
    let b = sig.UseWire(1)
    let bb = UseBlackBox(
        "blackbox",
        [Port(2), Port(1)],
        [Port(2)],
        [a, b]
    )

.. image:: imgs/wires-and-primitives/blackbox.svg

Next
----

We could construct entire circuits in this manner, connecting individual logic gates together one by one.
But this would quicky get tedious.
It is better to make a toolbox of larger, reusable components.
For this we will need a notion of a *subcircuit*.