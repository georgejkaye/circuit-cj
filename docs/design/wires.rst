Wires
=====

Circuits are constructed by connecting wires to different components.

Choosing a signature
--------------------

Before we begin, we must choose the *signature*, which specifies the value and
gate set used in this project.
Several signatures are provided as part of the standard library: we will use a
basic signature containing ``TRUE`` and ``FALSE`` values, and ``AND``, ``OR``
and ``NOT`` gates.

.. code-block:: scala

    import signatures.gate.belnapSignature
    let sig = belnapSignature

.. note::
    The causal user does not need to be too concerned over what a signature
    actually is; only that it specifies the components that can be used in a
    circuit.
    The interested reader can refer to :doc:`Signatures </advanced/signatures>`.

Making dangling wires
---------------------

Circuits are constructed by connecting ``Wire`` objects to circuit components.
To start building circuits, we must specify some dangling wires.
Wires are parameterised by a ``width``, which determines how many bits flow
through each wire.

.. code-block:: scala

    let a = sig.UseWire(1)
    let b = sig.UseWire(8)

In a wire ``w`` carrying multiple bits, we consider ``w[0]`` to be the
*least significant bit* and ``w[n-1]`` to be the *most significant bit*.

.. note::
    Conventionally, functions starting with ``Use`` return one or more ``Wire``
    objects , so they can immediately be passed to other functions.

We

.. code-block:: scala

    a.WriteDotToFile(0, "wire")


.. image:: imgs/wires/split-1.svg


Splitting wires
---------------

When we have a wire containing multiple bits, we sometimes want to deal with
only some of them.
For example, we might want to use the least significant bit as some output flag.
To split wires apart, use the ``Split`` functions in the ``components`` package.

.. code-block:: scala

    import components.Split

There are multiple ways wires can be split.

.. code-block:: scala

    // Split into consituent bits
    let a = sig.UseWire(8)
    let ws = Split(a)

.. image:: imgs/wires/split-1.svg

.. code-block:: scala

    // Split at the first bit
    let b = sig.UseWire(8)
    let (lhs, rhs) = Split(b, 1)

.. image:: imgs/wires/split-2.svg

.. code-block:: scala

    // Split into wires of width 1, 3, 4
    let c = sig.UseWire(8)
    let ws2 = Split(c, [1, 3, 4])

.. image:: imgs/wires/split-3.svg

.. warning::
    When splitting a wire by explicitly setting the wire widths, make sure they
    sum to the width of the original wire!

Combining wires
---------------

The opposite is also true: it can be more convenient to combine two wires into
one, *concatenating* their contents.

.. code-block:: scala

    let a = sig.UseWire(4)
    let b = sig.UseWire(4)
    let c = sig.UseWire(8)

.. code-block:: scala

    // Combine just two wires
    let w1 = Combine(a, b)

.. image:: imgs/wires/combine-1.svg

.. code-block:: scala

    // Combine an arbitrary number of wires
    let w2 = Combine([a, b, c])

.. image:: imgs/wires/combine-2.svg