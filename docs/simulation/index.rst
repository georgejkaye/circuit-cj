Evaluation
==========

Once circuits have been designed, we need to *simulate* them in order to verify
their correctness.
To do this, we use an *evaluator*.

First, we will create a circuit and remind ourselves of what it looks like.

.. code-block:: scala

    import examples.gate.Accumulator

    let sig = belnapSignature
    // Make a circuit
    let acc = Accumulator(initial: 0, width: 4)
    acc.WriteDotToFile("dot/acc", signed: false)

.. image:: imgs/acc.svg

This circuit is an accumulator with the internal state set to some initial
value.
At each tick, the input is added to the current state; the result of this is set
as the new state and also produced as the output.

Creating an evaluator
---------------------

Now we will make the actual evaluator.

.. code-block:: scala

    // Make the evaluator
    let eval = Evaluator(sig, acc)

The evaluator creates a version of the circuit in which the combinational logic
is separated from the state: the former is compressed into a 'Mealy core'.

.. code-block:: scala

    eval.WriteDotToFile("eval-0", signed: false)

.. image:: imgs/eval-0.svg

If we peek inside the Mealy core we can see how this relates to the original
circuit.

.. code-block:: scala

    eval.WriteDotToFile("eval-1", depth: 1, signed: false)

.. image:: imgs/eval-1.svg

An evaluator is fed inputs and transforms the circuit appropriately, producing
the outputs of the circuit but also the next internal state so it is ready to
take the next input.

.. code-block:: scala

    let input = Signal([TRUE, FALSE, FALSE, FALSE]) // 0001
    eval.PerformCycle(input)
    eval.WriteDotToFile("after-1", signed: false)

.. image:: imgs/after-1.svg

We set the initial value as 0, and input ``0001`` (1), so we would expect the
circuit to output 1 at this tick.
If we inspect the outputs of the evaluated circuit, we can see that this is
indeed the case!

If we are in a signature that implements ``Decimal``, we can give inputs
as numbers rather than having to convert them to binary first.

.. code-block:: scala

    eval.PerformCycle(2, signed: false)
    eval.WriteDotToFile("after-2", signed: false)

.. image:: imgs/after-2.svg

We can also perform multiple cycles at once.

.. code-block:: scala

    let waveform = sig.BuildWaveform(signals: [3, 4], width: 4, signed: false)
    eval.PerformCycle(waveform: waveform)
    eval.WriteDotToFile("after-3-and-4", signed: false)

.. image:: imgs/after-3-and-4.svg

Input-output strings
--------------------

Rather than drawing and inspecting the graphs, you can get the input-output
history as a string.

.. code-block:: scala

    println(eval.GetInputOutputHistoryString())

.. code-block:: bash

    Tick   Input      Output
    ==========================
    0      (0001)     (0001)
    1      (0010)     (0011)
    2      (0011)     (0110)
    3      (0100)     (1010)

As always, we can interpret this as decimal with the ``signed`` argument.

.. code-block:: scala

    println(eval.GetInputOutputHistoryString(signed: false))

.. code-block:: bash

    Tick   Input   Output
    =====================
    0      (1)     (1)
    1      (2)     (3)
    2      (3)     (6)
    3      (4)     (10)

Waveform diagrams
-----------------

A more intuitive way of visualising the input-output behaviour of a circuit is
with a *waveform diagram*.

.. code-block:: scala

    println(eval.GetInputOutputHistoryString())

.. code-block:: bash

    A ──────────────────────────────────
        |0001   |0010   |0011   |0100
    ────────────────────────────────────
    [3]
        ────────────────────────────────
    [2]                         ┌───────
        ────────────────────────┘
    [1]         ┌───────────────┐
        ────────┘               └───────
    [0]  ────────┐       ┌───────┐
                 └───────┘       └──────
    ────────────────────────────────────

    S ──────────────────────────────────
        |0001   |0011   |0110   |1010
    ────────────────────────────────────
    [3]                         ┌───────
        ────────────────────────┘
    [2]                 ┌───────┐
        ────────────────┘       └───────
    [1]         ┌───────────────────────
        ────────┘
    [0] ────────────────┐
                        └───────────────
    ────────────────────────────────────

Alternatively, the headings can be represented in decimal.

.. code-block:: scala

    eval.DrawWaveformDiagram(signed: false)

.. code-block:: bash

    A ──────────────────────────────────
        |1      |2      |3      |4
    ────────────────────────────────────
    [3]
        ────────────────────────────────
    [2]                         ┌───────
        ────────────────────────┘
    [1]         ┌───────────────┐
        ────────┘               └───────
    [0] ────────┐       ┌───────┐
                └───────┘       └───────
    ────────────────────────────────────

    S ──────────────────────────────────
        |1      |3      |6      |10
    ────────────────────────────────────
    [3]                         ┌───────
        ────────────────────────┘
    [2]                 ┌───────┐
        ────────────────┘       └───────
    [1]         ┌───────────────────────
        ────────┘
    [0] ────────────────┐
                        └───────────────
    ────────────────────────────────────

.. note::
    Waveform visualisation was inspired by a similar tool developed as part of
    Hardcaml: https://github.com/janestreet/hardcaml_waveterm

Customising waveform display
****************************

As a text string, each waveform is rendered as multiple horizontal slices known
as *levels*.
How levels are drawn is determined by two functions in the ``ValueSymbol``
interface.

.. code-block:: scala

        func GetWaveformLevel() : Option<Int64>

This function assigns each value to a(n optional) level that will represent
that value in the waveform.
The higher the number, the higher on the screen the value will be drawn.

.. code-block:: scala

        static func GetWaveformHeight() : Int64

This function specifies how much space to allocate for drawing the waveform.
Note that if this is smaller than a level returned by ``GetWaveformLevel``,
then this level will not be rendered at all!