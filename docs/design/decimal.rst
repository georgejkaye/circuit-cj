Decimal
=======

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

.. code-block:: scala

    let sig = belnapSignature
    let n1 = sig.UseSignalFromInt(12, width: 4, signed: false)

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

    let n2 = sig.UseSignalFromInt(-3, width: 4, signed: true)
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

Waveforms
---------


Again, if operating in a signature in which signals model decimal numbers, we
can specify them with integers.

.. code-block:: scala

sig.UseOpenWaveformFromInt([0,1,2,3], width: 2, signed: false)

.. image:: imgs/state/waveform-from-int-0.svg

.. image:: imgs/state/waveform-from-int-1.svg

.. image:: imgs/state/waveform-from-int-2.svg

Registers
---------

If using a signature where the signals can be interpreted as numbers, it is
possible to eliminate the stage of creating the signal.

.. code-block:: scala

    let a = sig.UseWire(4)
    let d = UseSimpleRegister(initial: 5, signed: false, input: signal)

Both result in the same thing:

.. image:: imgs/state/simple-register.svg