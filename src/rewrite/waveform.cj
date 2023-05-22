package rewrite

let offSignalString = " "
let onSignalString = "─"
let highToLowUpString = "┐"
let highToLowDownString = "└"
let lowToHighUpString = "┌"
let lowToHighDownString = "┘"
let upDownString = "|"


func SignalOverTimeToWaveformString<V, T>(
    ticks : ArrayList<T>, fn : (T) -> Option<Signal<V>>, width : Int64
) : String
    where V <: ValueSymbol<V>
{
    let linesPerValue = V.GetHighestWaveformLevel() + 1
    let totalLines = linesPerValue * width
    fold_left(
        { acc, currentLine =>
            let currentBit = currentLine / linesPerValue
            let currentLevel = (linesPerValue - (currentLine % linesPerValue) - 1)
            let row = fold_left(
                { acc, currentTick =>
                    let currentOutput = ticks[currentTick]
                    let currentString = match(fn(currentOutput)) {
                        case None => offSignalString
                        case Some(s) =>
                            let currentValue = s.GetBit(currentBit)
                            match(currentValue.GetWaveformLevel()) {
                                case None => offSignalString
                                case Some(level) =>
                                    if(level == currentLevel) {
                                        onSignalString
                                    } else {
                                        offSignalString
                                    }
                            }
                    }
                    "${acc}${currentString}"
                }, "${currentLevel}", end: ticks.size
                )
            let concattedString = "${acc}${row}"
            let newLines =
                if(currentLine != totalLines - 1){
                    if(currentLevel == 0) {
                        "\n\n"
                    } else {
                        "\n"
                    }
                } else {
                    ""
                }
            "${concattedString}${newLines}"
        }, "", end: totalLines
    )
}

func SignalsToWaveformString<V, T>(
    signals : Array<ArrayList<T>>, fn : (T) -> Option<Signal<V>>,
    widthFn : (Int64) -> Int64
) : String
    where V <: ValueSymbol<V>
{
    let waveforms = mapi<ArrayList<T>, String>(
        { xs, i => SignalOverTimeToWaveformString<V, T>(xs, fn, widthFn(i)) },
        signals
    )
    concatStrings(waveforms, delimiter: "\n\n")
}