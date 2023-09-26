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