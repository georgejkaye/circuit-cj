Primitives
==========

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

.. image:: imgs/primitives/and.svg

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

.. image:: imgs/primitives/and-or-not.svg

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

.. image:: imgs/primitives/blackbox.svg