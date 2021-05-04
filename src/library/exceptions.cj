package library

class NotEnoughBitsException <: Exception {
    init(){
        print("Must be at least one bit")
    }
}