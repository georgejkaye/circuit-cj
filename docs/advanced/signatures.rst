Signatures
==========

When designing a circuit, everything you do is parameterised by a *signature*.
A signature determines the *values* that can flow in the wires of a circuit and
the *primitives* can be used to build a circuit along with their
input-output behaviours.

The Belnap signature
--------------------

The classic example of a signature is the *Belnap* signature, named after
`Belnap's four valued logic <https://en.wikipedia.org/wiki/Four-valued_logic#Belnap>`_.
It is perfectly acceptable to take this signature as given and use CircuitCJ
without even worrying about how signatures work behind the scenes.

Values
******

As the name suggests, there are four values in the Belnap signature.

* ``NONE`` (no signal, unknown)
* ``FALSE``
* ``TRUE``
* ``BOTH`` (both signals at once, short circuit)

The ``FALSE`` and ``TRUE`` values are the ones most work will be done with; the
other two are for special cases.

Primitives
**********

A variety of standard primitives make up the Belnap signature.

* ``BUF``
* ``NOT``
* ``AND``
* ``OR``
* ``NAND``
* ``NOR``
* ``XOR``
* ``XNOR``

Finite lattices
---------------

To create a signature, first a set of values that form a *finite lattice* must
be created.
Essentially, a lattice is a partial order with both a *minimum* and a *maximum*
element.
Subsequently, any two elements ``x`` and ``y`` have a *least upper bound* (the
lowest element ``z`` such that both ``x <= z`` and ``y <= z`` and *greatest
lower bound* (the greatest element ``z`` such that both ``z <= x`` and
``z <= y``).
These operations are also known as the *join* and *meet* respectively.

In our context, the lattice structure is used to determine the *information
content* of a given value.
For example, in the Belnap signature the ``FALSE`` and ``TRUE`` values clearly
have more information than ``NONE``, which has no information, but less than
``BOTH``, which has too much information.
Therefore, the lattice structure on the Belnap signature is as below:

.. code-block::

             BOTH
            /    \
        FALSE     TRUE
            \    /
             NONE

Here, ``NONE`` is the minimum element and ``BOTH`` is the maximum element.

An alternative lattice structure on a larger set of values could be:

.. code-block::

               BOTH
              /    \
   STRONG FALSE     STRONG TRUE
             |      |
    WEAK FALSE      WEAK TRUE
              \    /
               NONE


Implementing a lattice
----------------------

For a type ``V`` to be used as a type of value symbols, it must implement
the ``ValueSymbol`` interface.
First off, this means it must implement the following interfaces:

* ``LessOrEqual<T>``
* ``Equatable<T>``
* ``Hashable``
* ``ToString``

It must also implement ``ValueSymbol<V>``:

.. code-block:: scala

    interface ValueSymbol<V> {
        static func GetDisconnected() : V
        func GetWaveformLevel() : Option<Int64>
        static func GetWaveformHeight() : Int64
    }

The ``GetDisconnected()`` function picks the value from ``V`` that acts as a
*disconnected* value.
The remaining two functions pertaining to waveform visualisation, and are
detailed in :doc:`Evaluation </simulation/index>`.

.. code-block:: scala

    FiniteLattice<V>(
        valueSet : HashSet<V>
    )

The ``LessOrEqual`` implementation is used to automatically determine the
lattice structure when creating the lattice, so only the value set needs to be
specified.
If there is no suitable lattice structure on the values, an exception will be
thrown.

.. code-block:: scala

    enum Value {
        | NONE | FALSE | TRUE | BOTH
    }

    // implement the interfaces...

    extend Value <: ValueSumbol<Value> { ... }

    let valueSet = HashSet([NONE, FALSE, TRUE, BOTH])
    let lattice = FiniteLattice(valueSet)

Specifying the primitives
-------------------------

The primitives are simpler to specify; a type of primitives ``T`` must implement
the following standard interfaces:

* ``Hashable``
* ``Equatable<T>``
* ``HasName``
* ``ToString``

``T`` must also implement the interface ``Specifiable``

.. code-block:: scala

    struct Port(let width : Int64, let name: Option<String>)

    interface Specifiable {
        func GetInputPorts() : Array<Port>
        func GetOutputPorts() : Array<Port>
    }

There are no special functions to implement in the ``PrimitiveSymbol<V, G>``
interface, but extending it serves to parameterise the values that the
primitives operate over.

.. code-block:: scala

    enum Primitive {
        | BUF | NOT | AND | OR | NAND | NOR | XOR | XNOR
    }

    // implement the interfaces

    // Parameterise appropriately
    extend Primitive <: PrimitiveSymbol<Value, Primitive> {}

    let gateSet = HashSet([BUF, NOT, AND, OR, NAND, NOR, XOR, XNOR])

Interpreting the primitives
---------------------------

So far the primitive symbols are just that: symbols.
They must also be assigned an *interpretation*: a function from values to
values.

.. code-block:: scala

    func not(a : Value) {
        match(a) {
            case NONE => NONE
            case FALSE => TRUE
            case TRUE => FALSE
            case BOTH => BOTH
        }
    }

    // other helpers...

    func Interpretation(p : Primitive) :
        (Array<Signal<Value>>) -> (Array<Signal<Value>>)
    {
        { signals =>
            match(p) {
                case NOT => not(signals.GetBit(0))
                ...
            }
        }
    }

Creating a signature
--------------------

A signature is made by combining the pieces we have just discussed.

.. code-block:: scala

    Signature<V, G>(
        name : String,
        latticeStructure : FiniteLattice<V>,
        gateSet : HashSet<G>
        gateInterpretation : (G) -> ((Array<Signal<V>>) -> Array<Signal<V>>)
    )

Additional functions
--------------------

It is often advantageous to specify functions to make building circuits in your
signature easier.
For some inspiration, you can look at the functions specified in the
``signatures.gate`` package.