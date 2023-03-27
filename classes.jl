#=
classes:
- Julia version: 
- Author: alexa
- Date: 2023-03-25
=#

#abstract type Object end
#struct Class <: Object

struct Class
    name::String
    superclasses::Vector{Class}
    slots::Dict{Symbol, Any}

    function Class(name::String, superclasses, slots=Dict{Symbol, Any}())
        new(name, superclasses, slots)
    end
end

# global dictionary to keep track of defined classes
class_registry = Dict{String, Class}()

object_class = Class("Object", [], Dict())
class_registry["Object"] = object_class

function defclass(name::String, superclasses, slots)
    slots_dict = Dict(slot => nothing for slot in slots)
    
    new_superclasses = Vector{Class}()
    
    #= all classes inherit, directly or indirectly from Object class=#
    for classe in superclasses
        class_obj = class_registry[string(classe)]
        push!(new_superclasses, class_obj)
    end

    if !(:Object in superclasses)
        class_objet = class_registry["Object"]
        push!(new_superclasses, class_objet)
    end
    
    new_classe = Class(name, new_superclasses, slots_dict)
    class_registry[name] = new_classe
end

function new(classe::Symbol; kwargs...)
    class_obj = class_registry[string(classe)]
    for (slot, value) in class_obj.slots
        if haskey(kwargs, slot)
            class_obj.slots[slot] = kwargs[slot]
        end
    end
    return class_obj
end

defclass("ComplexNumber", [], [:real, :imag])
defclass("Shape", [], [])
defclass("Device", [], [])

c1 = new(:ComplexNumber, real=1, imag=2)

defclass("Line", [:Shape], [:from, :to])
defclass("Circle", [:Shape], [:center, :radius])

defclass("Screen", [:Device], [])
defclass("Printer", [:Device], [])

function getproperty(classe::Class, slot::Symbol)
    #return get(classe.slots, slot, nothing)
    if haskey(classe.slots, slot)
        return classe.slots[slot]
    end

    # search for the property in superclasses
    for superclass in classe.superclasses
        value = getproperty(class_registry[superclass], slot)
        if value !== nothing
            return value
        end
    end

    error("$(classe.name) does not have slot $slot")
end

getproperty(c1, :real)

function setproperty!(classe::Class, slot::Symbol, value::Any)
    if haskey(classe.slots, slot)
        classe.slots[slot] = value
    else
        error("$(classe.name) does not have slot $slot")
    end
    return classe.slots[slot]
end

setproperty!(c1, :imag, -1)

# does not work, stackoverflow error infinite loop
function Base.getproperty(classe::Class, slot::Symbol)
    getproperty(classe, slot)
end

#println(c1.real)
#c1.imag += 3

function add(a, b)
    println("I entered the add generic function.")
end

#=function add(a::Complexnumber, b::Complexnumber)
    real_sum = a.real + b.real
    imag_sum = a.imag + b.imag
    return new(ComplexNumber, real=real_sum, imag=imag_sum)
end

c2 = new(ComplexNumber, real=3, imag=4)

println(add(c1, c2))

function print_object(obj, io)
    println("I entered the print generic function.")
end=#