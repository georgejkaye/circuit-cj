package library

import debug.*

class NotEnoughBitsException <: Exception {
    init(){
        Debug("Must be at least one bit")
    }
}

class BadInputException <: Exception {
    init(function : String, wire : String, n1 : Int64, name: String, n2 : Int64){
        Debug("${function}: Expected input '${wire}' to be of type n->${n1} but instead got type n->${n2}")
    }
}