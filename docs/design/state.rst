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
    v.WriteDotToFile("value")

.. image:: imgs/state/value.svg

In the ``Belnap`` signature we can also ``Use`` values directly:

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

    let s = sig.UseSignal(Signal([TRUE, FALSE, TRUE, FALSE])) // bin 0101 = dec 9

At the highest level, a signal is just represented by a single block.

.. code-block:: scala

    s.WriteDotToFile("signal-0")

.. image:: imgs/state/signal-1.svg

When drawing graphs with greater depths, signals are not expanded by default in
order to reduce clutter.
They can be forced to expand with the ``expandSignals`` flag.

.. code-block:: scala

    s.WriteDotToFile("signal-1", depth: 1, expandSignals: true)

.. image:: imgs/state/signal-2.svg

Delay
-----

Operations in ciruits do not all happen instantaneously.
Indeed, we may wish to *delay* signals for a certain period of time.

In CircuitCJ, the notion of delay is modelled relative to ticks of a *clock* in
the background.
A *delay block* delays its input for one tick of this clock.

The exact nature of the clock and a delay may differ depending on what one is
modelling.
If one is concerned with modelling high level logical operations, each tick
could represent a new cycle and a delay block as a register that delays a signal
to the next cycle.
At a lower level abstraction, each tick could be a unit of time and a delay
some natural capacitance of wires.

Delay blocks can be seen as the converse of value blocks: their initial value is
the disconnected value, and in the following ticks they will produce the
input from the previous cycle.

.. code-block:: scala

    let a = sig.UseWire(8)
    let d = UseDelay(a)

In circuit diagrams, the delay is represented as a yellow box.

.. image:: imgs/state/delay.svg

On the first tick of the clock, this circuit will produce the disconnected
value.
On each subsequent tick of the clock, it will produce the input from the
previous tick.


Register
--------

It is often the case that there will be some 'initial value' stored in a
register: we don't always want to produce the disconnected value straight away!
The simplest register in CircuitCJ is the join of a signal and a delay.

.. code-block:: scala

    let a = sig.UseWire(4)
    let signal = Signal([TRUE, FALSE, TRUE, FALSE])
    let d = UseSimpleRegister(a, signal)

.. note::
    The register created here is a logical abstraction; real-world latches and
    flipflops hold state by using feedback loops and the delay in wires.

At the highest level of drawing, registers are contained within their own block.

.. code-block:: scala

    d.WriteDotToFile("register-0")

.. image:: imgs/state/register-0.svg

Like signals, registers do not normally get expanded in drawn graphs.

.. code-block:: scala

    d.WriteDotToFile("register-1", depth: 1, expandSignals: true)

.. image:: imgs/state/register-1.svg

Waveforms
---------

By combining value blocks and delay blocks we can define *waveforms*: sequences
of signals over time.
These are implemented by connecting simple registers together one after the
other.

.. code-block:: scala

    import syntax.{Signal, Waveform}

    let a = sig.UseWire(2)
    let v1 = Signal([TRUE, FALSE])
    let v2 = Signal([FALSE, TRUE])
    let wf = UseOpenWaveform(waveform: Waveform([v1, v2]), input: a)

At the highest depth, waveforms are drawn as a single block.

.. code-block:: scala

    wf.WriteDotToFile("open-waveform-0")

.. image:: imgs/state/open-waveform-0.svg

Descending a level shows us the registers used to construct it.

.. code-block:: scala

    wf.WriteDotToFile("open-waveform-1", depth: 1, expandSignals: true)

.. image:: imgs/state/open-waveform-1.svg

Descending again lets us peek into the registers.

.. code-block:: scala

    wf.WriteDotToFile("open-waveform-2", depth: 2, expandSignals: true)

.. image:: imgs/state/open-waveform-2.svg

A waveform can also be *closed* by capping off its inputs.

.. code-block:: scala

    let v1 = Signal([TRUE, FALSE])
    let v2 = Signal([FALSE, TRUE])
    let v3 = Signal([FALSE, FALSE])
    let wf = sig.UseClosedWaveform([v1, v2, v3])

This is

.. code-block:: scala

    wf.WriteDotToFile("closed-waveform-0")

.. image:: imgs/state/closed-waveform-0.svg

By expanding this block we can se how the closed waveform is constructed by
applying a disconnected value to an open waveform.

.. code-block:: scala

    wf.WriteDotToFile("closed-waveform-1", depth: 0, expandSignals: true)

.. image:: imgs/state/closed-waveform-1.svg


Feedback
--------

When designing circuits, we often want to feedback an output to some point
earlier in the circuit, normally in the next cycle of execution.

.. code-block:: scala

    let a = sig.UseWire(8)
    let b = sig.UseWire(8)
    let and = UseAnd(a, b)
    // Connect the output of the and gate to the a wire
    Feedback(and, a)
    and.WriteDotToFile("feedback")

.. image:: imgs/state/feedback.svg

.. warning::
    A wire can only be fed back to if it is a dangling wire made with
    ``UseWire``: if you try to feed back to a vertex obtained as the output of a
    gate an exception will be thrown.

Note that in the drawn graph the feedback loop is drawn in red.
This is because this feedback loop may have created a *combinational loop*, a
feedback loop which does not pass through a memory element.
This is usually not desirable; we would prefer that all feedback is
*delay-guarded*.
This can be done manually by combining the ``Delay`` functions above with the
``Feedback`` function, but functions are also provided to do this in one step.

.. code-block:: scala

    let a = sig.UseWire(8)
    let b = sig.UseWire(8)
    let and = UseAnd(a, b)
    // Connect the output of the and gate to the a wire
    DelayGuardedFeedback(and, a)
    and.WriteDotToFile("delay-guarded-feedback")

.. image:: imgs/state/delay-guarded-feedback.svg

.. code-block:: scala

    let a = sig.UseWire(2)
    let b = sig.UseWire(2)
    let and = UseAnd(a, b)
    // Connect the output of the and gate to the a wire
    RegisterGuardedFeedback(and, a, initial: Signal([TRUE, FALSE]))
    and.WriteDotToFile("register-guarded-feedback")

.. image:: imgs/state/register-guarded-feedback.svg

.. note::
    Graphviz really struggles to render feedback loops, as can be seen in the
    generated graphs. The dream is to integrate CircuitCJ with ``sd-visualiser``
    (https://github.com/sdvisualiser/sd-visualiser) for very pretty graphs, but
    this is unimplemented and might require a bit of effort.

Infinite waveforms
------------------

By combining feedback with waveforms, we can create *infinite* waveforms.

.. code-block:: scala

    let v1 = Signal([TRUE, FALSE])
    let v2 = Signal([FALSE, TRUE])
    let wf = sig.UseInfiniteWaveform(waveform: Waveform([v1, v2]))
    wf.WriteDotToFile("infinite-waveform-0")

.. image:: imgs/state/infinite-waveform-0.svg

.. code-block:: scala

    wf.WriteDotToFile("infinite-waveform-1", depth: 1, expandSignals: true)

.. image:: imgs/state/infinite-waveform-1.svg

.. code-block:: scala

    wf.WriteDotToFile("infinite-waveform-2", depth: 2, expandSignals: true)

.. image:: imgs/state/infinite-waveform-2.svg

.. code-block:: scala

    wf.WriteDotToFile("infinite-waveform-3", depth: 3, expandSignals: true)

.. image:: imgs/state/infinite-waveform-3.svg
