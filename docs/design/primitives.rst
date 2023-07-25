Primitives
==========

Wires on their own are pretty useless.
To add some actual computation to circuits we need some sort of *logic gates*,
or *primitives* as they are known in CircuitCJ.
Each primitive has an associated *arity* and *coarity*: an array of widths that
are the inputs and outputs of each primitive.

The set of available primitives is specified in the signature.
For example, the default Belnap signature has primitives ``AND`` (``[2]->[1]``),
``OR`` (``[2]->[1]``) and ``NOT`` (``[1]->[1]``).

Gates
-----

To use a logic gate, we must specify the wires that will act as its inputs:

.. code-block:: scala

    import components.UseGate

    let a = sig.UseWire(1)
    let b = sig.UseWire(1)
    let and = UseGate(AND, [a, b])

.. image:: imgs/primitives/and.svg

In the Belnap signature we can also specify gates directly.

.. code-block:: scala

    import signatures.gate.{UseAnd, UseOr, UseNot}

    let and = UseAnd(a, b)
    let or = UseOr(a, b)
    let not = UseNot(a)


Using a gate returns another ``Wire`` that can be used in other gates.
Constructing circuits is therefore as simple as passing the output of each gate
to the next one.
If desired, wires can be used multiple times.

.. code-block:: scala

    let a = sig.UseWire(1)
    let b = sig.UseWire(1)
    let and = UseAnd(a, b)
    let or = UseOr(and, b)
    let not = UseNot(or)

.. image:: imgs/primitives/and-or-not.svg


Black boxes
-----------

A final component we may wish to use in our circuits is a *black box*.
A black box is a component that we know nothing about except its interface.

.. code-block:: scala

    import syntax.Port
    import components.UseBlackbox

    let a = sig.UseWire(2)
    let b = sig.UseWire(1)
    let bb = UseBlackbox(
        "blackbox",
        [Port(2), Port(1)],
        [Port(2)],
        [a, b]
    )

.. image:: imgs/primitives/blackbox.svg