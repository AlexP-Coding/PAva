#=
classes:
- Julia version: 
- Author: alexa
- Date: 2023-03-25
=#

#acho que nao e suposto ser assim
abstract type Object end

struct Class <: Object
    name::String
    superclasses::Vector
    slots::Vector{Symbol}
end

function Class(name::String, superclasses, slots=Symbol[])
    new(name, superclasses, slots)
end

function defclass(name::String, superclasses, slots)
    new_classe = Class(name, superclasses, slots)
    return new_classe
end

ComplexNumber = defclass("ComplexNumber", [], [:real, :imag])

println(ComplexNumber.name)
println(ComplexNumber.superclasses)
println(ComplexNumber.slots[1])
println(ComplexNumber.slots[2])

mutable struct Complexnumber
    class::Class
    real::Int64
    imag::Int64
end

function new(classe::Class; kwargs...)
    instance = Complexnumber(classe, 0, 0)
    for i in 1:length(classe.slots)
        slot = classe.slots[i]
        if haskey(kwargs, slot)
            setproperty!(instance, slot, kwargs[slot])
        end
    end
    return instance
end

c1 = new(ComplexNumber, real=1, imag=2)

println(typeof(c1))
println(c1.real)

getproperty(c1, :real)
getproperty(c1, :imag)
setproperty!(c1, :imag, -1)
c1.imag += 3

function add(a, b)
    println("I entered the add generic function.")
end

function add(a::Complexnumber, b::Complexnumber)
    real_sum = a.real + b.real
    imag_sum = a.imag + b.imag
    return new(ComplexNumber, real=real_sum, imag=imag_sum)
end

c2 = new(ComplexNumber, real=3, imag=4)

println(add(c1, c2))

function print_object(obj, io)
    println("I entered the print generic function.")
end