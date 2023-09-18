State
=====

So far everything has been *combinational*: the circuits we have created will
always produce the same outputs given some inputs.
Effectively, these circuits have no *memory*.
To add this we need a concept of *state*.

Values
------

The first kind of state is a *value block*, which is initialised with some
constant.
Value blocks represent the *initial state* of a circuit, or the *inputs* to a
circuit.

The exact constants one can use are specified by the signature.
All signatures must contain a 'disconnected' value, representing the total lack
of information.
The default Belnap signature contains four constants:

- ``NONE`` (disconnected, unknown)
- ``FALSE``
- ``TRUE``
- ``BOTH`` (illegal, short-circuit)

A value block will 'produce' its initialised constant on the first cycle of
execution only.
In the following cycles it will 'produce' the distinguished disconnected value.
In essence, value blocks are *instantaneous*.

To ``Use`` a value, the signature provides the following function:

.. code-block:: scala

    let v = sig.UseValue(TRUE)

.. image:: imgs/state/value.svg

In the default signature we can also ``Use`` values directly:

.. code-block:: scala

    let v1 = UseBottom()
    let v2 = UseTrue()
    let v3 = UseFalse()
    let v4 = UseTop()

Signals
-------

It is very rare that we will only be dealing with single bit values.
Rather than juggling multiple values, it is better to collect them together into
arbitrary-width *signals*.
Recall that the convention is that the value at position ``0`` is the least
significant bit.

.. code-block:: scala

    let s = sig.UseSignal([TRUE, FALSE, TRUE, FALSE]) // bin 0101 = dec 9

At the highest level, a signal is just represented by a single block.

.. image:: imgs/state/signal-1.svg

But as always we can look inside it and see the individual values.

.. image:: imgs/state/signal-2.svg

Often in circuit design, the signals represent numbers.
When using the Belnap signature, we can ``Use`` values directly from decimal numbers without having to convert them.

.. code-block:: scala

    let n1 = UseUnsignedValueFromInt(10, width: 4)

.. image:: imgs/state/unsigned-value-1.svg

.. image:: imgs/state/unsigned-value-2.svg

.. code-block:: scala

    let n2 = UseSignedValueFromInt(-10, width: 4)

.. image:: imgs/state/signed-value-1.svg

.. image:: imgs/state/signed-value-2.svg



A single wire of the appropriate width will be returned.

.. warning::
    Make sure your number can fit into the specified width! If it can't, you will get an error.

Delay
-----

Operations in ciruits do not all happen instantaneously.
Indeed, we may wish to hold some value to the next tick of the clock.
This is usually done with a *register*.

In CircuitCJ, the notion of delay is abstracted into a *delay block*.
At a high level, one can view a delay block as some register; at a low level,
the delay block could model the capacitance in wires.

Delay blocks can be seen as the converse of value blocks: their initial value is
the disconnected constant, and in the following cycles they will produce the
input from the previous cycle.

.. code-block:: scala

    let a = sig.UseWire(8)
    let d = UseDelay(a)

In circuit diagrams, the delay is represented as a yellow box:

.. image:: imgs/state/delay.svg

On the first tick of the clock, this circuit will produce the disconnected wire.
On each subsequent tick of the clock, it will produce the input from the
previous tick.

It is often the case that there will be some 'initial value' stored in a
register: we don't always want to produce the disconnected value straight away!
The simplest register in CircuitCJ is the join of a signal and a delay as above.

.. code-block:: scala

    let a = sig.UseWire(4)
    let signal = Signal([TRUE, FALSE, TRUE, FALSE])
    let d = UseSimpleRegister(a, signal)

If using a signature where the signals can be interpreted as numbers, it is
possible to eliminate the stage of creating the signal.

.. code-block:: scala

    let a = sig.UseWire(4)
    let d = UseSimpleRegister(initial: 5, signed: false, input: signal)

Both result in the same thing:

.. image:: imgs/state/simple-register.svg

Waveforms
---------

By combining value blocks and delay blocks we can define *waveforms*: sequences
of values over time.
A *closed* waveform is capped off so it does not need any inputs:

.. code-block:: scala

    let v1 = Signal([TRUE, FALSE])
    let v2 = Signal([FALSE, TRUE])
    let v3 = Signal([FALSE, FALSE])
    let wf = sig.UseClosedWaveform([v1, v2, v3])

We can view waveforms at all sorts of levels of abstraction!

.. image:: imgs/state/waveform-1.svg

.. image:: imgs/state/waveform-2.svg

.. image:: imgs/state/waveform-3.svg

We can also define *open* waveforms, so we can specify some initial values that
are output before the rest of our circuit.

.. code-block:: scala

    let a = sig.UseWire(2)
    let b = sig.UseWire(2)
    let c = sig.UseWire(1)
    let add = UseRippleAdder(a, b, c)
    let v1 = Signal([TRUE, FALSE])
    let v2 = Signal([FALSE, TRUE])
    let wf = sig.UseOpenWaveform([v1, v2], add)

.. image:: imgs/state/open-waveform-1.svg

.. image:: imgs/state/open-waveform-2.svg

Again, if operating in a signature in which signals model decimal numbers, we
can specify them with integers.

.. code-block:: scala

    sig.UseOpenWaveformFromInt([0,1,2,3], width: 2, signed: false)

.. image:: imgs/state/waveform-from-int-0.svg

.. image:: imgs/state/waveform-from-int-1.svg

.. image:: imgs/state/waveform-from-int-2.svg

Feedback
--------

When designing circuits, we often want to feedback an output to some point
earlier in the circuit, normally in the next cycle of execution.

.. code-block:: scala

    let a = MakeWire(8)
    let b = MakeWire(8)
    let and = And(a, b)
    // Connect the output of the and gate to the a wire
    Feedback(and, a)

.. image:: imgs/state/feedback.svg

.. warning::
    A wire can only be fed back to if it is a dangling wire made with
    ``UseWire``: if you try to feed back to a vertex obtained as the output of a
    gate an exception will be thrown.

Often more than just a direct feedback loop is required.
Usually it is desirable that feedback is *delay-guarded*.
This can be done manually by combining the ``Delay`` functions above with the
``Feedback`` function, but functions are also provided to do this in one step.

.. code-block:: scala

    DelayGuardedFeedback(and, a)

.. image:: imgs/state/delay-guarded-feedback.svg

.. code-block:: scala

    RegisterGuardedFeedback(and, Signal([TRUE, FALSE, TRUE, FALSE]), a)

.. image:: imgs/state/register-guarded-feedback.svg

Infinite waveforms
------------------

By combining feedback with waveforms, we can create *infinite* waveforms.

.. code-block:: scala

    let v1 = Signal([TRUE, FALSE])
    let v2 = Signal([FALSE, TRUE])
    let wf = sig.UseInfiniteWaveform([v1, v2])

.. image:: imgs/state/infinite-waveform-1.svg

.. image:: imgs/state/infinite-waveform-2.svg
