import hypergraphs.*
import examples.*
import library.*

func main(){

    let ten = UnsignedValueFromInt(10, width: 4, name: "a")
    let two = UnsignedValueFromInt(10, width: 4, name: "b")
    let circ = Plus(a: ten, b: two, width: 4, sum: "sum", cout: "cout")

    WriteDotToFile(circ, "dot/main.dot")

    return 0
}
