import hypergraphs.*
import examples.*

func main(){
    let add = Adder(width: 2, sum: "sum", cout: "cout")
    WriteDotToFile(add, "dot/add.dot")
    return 0
}