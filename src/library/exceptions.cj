package library

class NotEnoughBitsException <: Exception {
    init(){
        print("Must be at least one bit\n")
    }
}

class BadInputException <: Exception {
    init(function : String, wire : String, n1 : Int64, name: String, n2 : Int64){
        print("${function}: Expected input ${wire} to be of type n->${n1} but '${name}' has type n->${n2}\n")
    }
}