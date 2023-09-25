Decimals
========

Often in circuit design, the signals represent numbers.
One could of course manually convert from numbers into the corresponding array
of values, but it is also possible to let CircuitCJ handle this.

To do this, the values of a signature need to implement the ``Decimal``
interface.

.. code-block:: scala

    interface Decimal<V> {
        static func UnsignedDecToSignal(x : Int64, width!: Int64) : Signal<V>
        static func SignedDecToSignal(x : Int64, width!: Int64) : Signal<V>
        static func UnsignedSignalToDec(signal : Signal<V>) : Option<Int64>
        static func SignedSignalToDec(signal : Signal<V>) : Option<Int64>
    }

The default Belnap values already implement the ``Decimal`` interface.
As we will now see, most constructors that create signals can be toggled to take decimal input by
adding a boolean ``signed`` argument.

Signals
-------

.. code-block:: scala

    let sig = belnapSignature
    let n1 = sig.UseSignal(12, width: 4, signed: false)

A single wire of the appropriate width will be returned.
Drawing graphs can also exploit the ``Decimal`` interface.

.. code-block:: scala

    n1.WriteDotToFile("unsigned-decimal-0", signed: false)

.. image:: imgs/decimal/unsigned-decimal-0.svg

.. code-block:: scala

    n1.WriteDotToFile(
        "unsigned-decimal-1", depth: 1, signed: false, expandSignals: true
    )

.. image:: imgs/decimal/unsigned-decimal-1.svg

Signed values are used in the same way.

.. code-block:: scala

    let n2 = sig.UseSignal(-3, width: 4, signed: true)
    n2.WriteDotToFile("signed-decimal-0", signed: true)

.. image:: imgs/decimal/signed-decimal-0.svg

.. code-block:: scala

    n1.WriteDotToFile(
        "signed-decimal-1", depth: 1, signed: true, expandSignals: true
    )

.. image:: imgs/decimal/signed-decimal-1.svg

.. warning::
    Make sure your number can fit into the specified width! If it can't, you
    will get an error.

Registers
---------

Signals specified as decimals can be used in registers.

.. code-block:: scala

    let a = sig.UseWire(4)
    let d = UseSimpleRegister(initial: 5, signed: false, input: signal)

Now the contents of registers are much clearer!

.. code-block:: scala

    reg.WriteDotToFile("dot/decimal-register-0", signed: false)

.. image:: imgs/decimal/decimal-register-0.svg

.. code-block:: scala

    reg.WriteDotToFile("dot/decimal-register-1", signed: false, expandSignals: true, depth: 1)

.. image:: imgs/decimal/decimal-register-1.svg

Waveforms
---------

As waveforms are just sequences of registers, we can specify them in terms of
decimals as well.

.. code-block:: scala

    let wf = sig.UseOpenWaveform([0,1,2,3], width: 2, signed: false)

The decimal representation will be shown in drawn graphs.

.. code-block:: scala

    wf.WriteDotToFile("dot/decimal-waveform-0", expandSignals: true)

.. image:: imgs/decimal/decimal-waveform-0.svg

.. code-block:: scala

    wf.WriteDotToFile("dot/decimal-waveform-1", expandSignals: true, depth: 1)

.. image:: imgs/decimal/decimal-waveform-1.svg

.. code-block:: scala

    wf.WriteDotToFile("dot/decimal-waveform-2", expandSignals: true, depth: 2)

.. image:: imgs/decimal/decimal-waveform-2.svg