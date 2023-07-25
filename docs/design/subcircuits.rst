Subcircuits
===========

A key concept when designing circuits is that of *subcircuits*.
Subcircuits are a collection of gates or even other subcircuits, together with
an interface.
They abstract away from the implementation of particular components, such as
adders, so that one can concentrate on the bigger picture.
In fact, the composite logic gates in the previous section were defined as
subcircuits.

Making a subcircuit
-------------------

First one must *make* a subcircuit.
This consists of designing a circuit and specifying its interface.

The ports on a circuit can optionally be named.
This is achieved using an ``InterfaceWire``:

.. code-block:: scala

    struct InterfaceWire {
        wire : Wire,
        name : Option<Name>
    }


A subcircuit is then made by providing arrays of ``InterfaceWire`` objects for
the inputs and outputs, along with a name for the circuit.

.. code-block:: scala

    func MakeSubcircuit(
        inputs  : Array<InterfaceWire>,
        outputs : Array<InterfaceWire>,
        name    : String
    ) : InterfacedHypergraph

For example:

.. code-block:: scala

    import components.{MakeSubcircuit, InterfaceWire}

    let a = sig.UseWire(2)
    let b = sig.UseWire(2)
    let c = sig.UseWire(2)
    let and = UseAnd(a, b)
    let or = UseOr(and, c)
    let subcircuit = MakeCircuit(
        [InterfaceWire(a, "A"), InterfaceWire(b, "B"), InterfaceWire(c, "C")],
        [InterfaceWire(or, "Z")],
        "subcircuit"
    )

.. image:: imgs/subcircuits/subcircuit.svg

.. note::
    Functions prefixed with ``Make`` return a subcircuit,

The subcircuit created by ``MakeSubcircuit`` is a snapshot of the circuit
'as-is'; any modifications made after the function call will not affect the
subcircuit.

Using a subcircuit
------------------

Once a subcircuit has been made, it can be *used* multiple times across a
circuit.
To use a subcircuit, its input wires must be provided.

.. code-block:: scala

    func UseSubcircuit(
        circuit : InterfacedHypergraph,
        inputs  : Array<Wire>
    ) : Array<Wire>


For example:

.. code-block:: scala

    // other code creating wires a, b, c...

    let outputs = UseSubcircuit(
        circ,
        [a, b, c]
    )


``UseSubircuit`` will return an array of ``Wire`` objects.
Some useful variants are provided for common numbers of outputs, to allow tuple
destructuring to be used on the output wires.

.. code-block:: scala

    func UseSubcircuit_1(
        circuit : InterfacedHypergraph,
        inputs  : Array<Wire>
    ) : Wire
    func UseSubcircuit_2(
        circuit : InterfacedHypergraph,
        inputs  : Array<Wire>
    ) : (Wire, Wire)
    func UseSubcircuit_3(
        circuit : InterfacedHypergraph,
        inputs  : Array<Wire>
    ) : (Wire, Wire, Wire)

Subcircuits can be provided as part of a signature.
In particular, several useful constructs are defined in the Belnap signature.