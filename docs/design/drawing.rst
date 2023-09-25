Drawing
=======

It can often be useful to *draw* the circuits we

Once we have specified a circuit with its interfaces, we can generate a graph
specified in the `Dot language <https://graphviz.org/doc/info/lang.html>`_  to
be rendered by `Graphviz <https://graphviz.org/>`_.

.. code-block:: scala

    import components.{MakeSubcircuit, UseRippleAdder}

    // Make a circuit that outputs only the sum of a ripple adder
    let a = sig.UseWire(4)
    let b = sig.UseWire(4)
    let c = sig.UseWire(1)
    let (sum, carry) = UseRippleAdder(a, b, c)
    let circuit = MakeSubcircuit(
        [InterfaceWire(a, "A"), InterfaceWire(b, "B"), InterfaceWire(c, "C")],
        [InterfaceWire(sum, "S")],
        "add"
    )
    // Draw this circuit to ./add-1.dot
    circuit.WriteDotToFile("add-1")

.. image:: imgs/subcircuits/ripple-adder-1.svg

Layers of abstraction
---------------------

When rendering graphs, we can choose the level of abstraction to view the
circuit at, by choosing the depth of subcircuits to peek into.

.. code-block:: scala

    // Highest level of abstraction, equivalent to not specifying depth
    // Write file ./dot/add-0.dot
    circuit.WriteDotToFile("add-0", depth: 0)

.. image:: imgs/subcircuits/ripple-adder-1.svg

.. code-block:: scala

    // Write file ./dot/add-1.dot
    circuit.WriteDotToFile("add-1", depth: 1)


.. image:: imgs/subcircuits/ripple-adder-2.svg

.. code-block:: scala

    // Write file ./dot/add-2.dot
    circuit.WriteDotToFile("add-2", depth: 2)


.. image:: imgs/subcircuits/ripple-adder-3.svg

Drawing wires
-------------

Whenever you have a handle on a wire you can draw a graph showing the current
structure of the circuit.
Note that this graph will not have any interfaces as these haven't been
specified yet!

.. code-block:: scala

    let a = sig.UseWire(1)
    let b = sig.UseWire(1)
    let or = UseOr(a, b)

    or.WriteDotToFile("dot/after-or")

.. image:: imgs/drawing/after-or.svg

.. code-block:: scala

    let and = UseAnd(b, or)
    and.WriteDotToFile("dot/after-and")

.. image:: imgs/drawing/after-and.svg

Unlike the graphs in subcircuits, the underlying graphs in wires are
mutable.
This means that the graph for a wire might look different after performing some
operations!

.. code-block:: scala

    or.WriteDotToFile("dot/after-or-2)

.. image:: imgs/drawing/after-or-2.svg