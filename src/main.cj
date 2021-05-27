import circuits.*
import examples.*
import debug.*
import settings.*

func main(){

    SetDotDir("dot")

    let and1 = True() * False() + AndGate()
    let spec = NewSpec(width: 1, name: "")
    let and2 = AndGate(lhs: InLink(spec: spec), rhs: and1)
    let circ = Feedback(input: and2, spec: spec)

    WriteDotToFile(and2, "circ")
    let red = TestRewrites(and2)
    WriteDotToFile(red, "red")

    return 0
}