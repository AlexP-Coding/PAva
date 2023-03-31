#=
classes:
- Julia version: 
- Author: alexa
- Date: 2023-03-25
=#

struct class
    name::Symbol
    direct_superclasses::Vector{class}
    direct_slots::Dict{Symbol, Any}
    metaclass::Union{Type{}, Nothing}

    function class(name::Symbol, direct_superclasses, direct_slots=Dict{Symbol, Any}(), metaclass=nothing)
        new(name, direct_superclasses, direct_slots, metaclass)
    end
end

# global dictionary to keep track of defined classes
#class_registry = Dict{Symbol, class}()

global Object = class(:Object, [], Dict())
#class_registry[:Object] = Object

function defclass(name::Symbol, direct_superclasses, direct_slots)
    #slots_dict = Dict(slot => nothing for slot in direct_slots)
    #println(direct_slots)
    slots_dict = Dict()

    for slot in direct_slots
        # only slot name is provided
        if isa(slot, Symbol)
            println("Is a symbol")
            slots_dict[slot] = nothing
        # slot name includes reader, writer or initform
        elseif isa(slot, Vector)
            println("Is a Vector")
            slot_name = slot[1]
            println(slot_name)
            slot_options = slot[2:end]
            println(slot_options)

            if isa(slot_name, Symbol)
                println("Vector slot name is a symbol")
                slots_dict[slot_name] = nothing
            else
                println("Vector with Name and Value")
                #slots_dict[slot] = direct_slots[slot]
                slots_dict[slot_name.first] = slot_name.second
            end
            
            for option in slot_options
                #if haskey(slot_options, :initform)
                if :initform in option
                    println("Vector slot name as initform")
                    #slots_dict[slot_name] = slot_options[:initform]
                    slots_dict[slot_name] = option.second
                #if haskey(slot_options, :reader)
                elseif :reader in option
                    println("Created a reader method")
        
                #if haskey(slot_options, :writer)
                elseif :writer in option
                    println("Created a writer method")
                end
            end

        # slot name with iniform value are provided
        else 
            println("Name and Value")
            #slots_dict[slot] = direct_slots[slot]
            #doing it like a pair
            slots_dict[slot.first] = slot.second
        end
    end
    
    
    #slots_dict = Dict(direct_slots[1] => nothing for slot in direct_slots)
    
    new_superclasses = Vector{class}()
    
    # all classes inherit, directly or indirectly from Object class
    for classe in direct_superclasses
        #class_obj = class_registry[classe]
        push!(new_superclasses, classe)
    end

    if !(Object in direct_superclasses)
        #class_objet = class_registry[:Object]
        push!(new_superclasses, Object)
    end
    
    new_classe = class(name, new_superclasses, slots_dict)
    #class_registry[name] = new_classe
    return new_classe
end

function new(classe::class; kwargs...)
    #class_obj = class_registry[classe]
    for (slot, value) in getfield(classe, :direct_slots)
        if haskey(kwargs, slot)
            getfield(classe, :direct_slots)[slot] = kwargs[slot]
        end
    end
    return classe
end

function Base.getproperty(classe::class, slot::Symbol)
    if slot == :slots
        return println([:name, :direct_superclasses, :direct_slots, :metaclass])
    end
    
    if haskey(getfield(classe, :direct_slots), slot)
        return getfield(classe, :direct_slots)[slot]
    end

    if slot == :direct_slots
        return println(keys(getfield(classe, :($slot))))
    end

    if isdefined(classe, slot)
        return getfield(classe, :($slot))
    end
    
    # search in superclasses
    for superclass in getfield(classe, :direct_superclasses)
        value = getproperty(superclass, slot)
        if value !== nothing
            return value
        end
    end

    error("$(classe.name) does not have slot $slot")
end

function Base.setproperty!(classe::class, slot::Symbol, value::Any)
    if haskey(getfield(classe, :direct_slots), slot)
        getfield(classe, :direct_slots)[slot] = value
    else
        error("$(classe.name) does not have slot $slot")
    end
    return getfield(classe, :direct_slots)[slot]
end

global Class = defclass(:Class, [], [])

Class.name
Class.slots

global ComplexNumber = defclass(:ComplexNumber, [], [:real, :imag])

global Shape = defclass(:Shape, [], [])
global Device = defclass(:Device, [], [])

c1 = new(ComplexNumber, real=1, imag=2)

ComplexNumber.name
ComplexNumber.direct_superclasses == [Object]
ComplexNumber.direct_slots

getproperty(c1, :real)
setproperty!(c1, :imag, -1)

c1.real
c1.imag
c1.imag += 3

#global CountingClass = defclass(:CountingClass, [Class], [counter=0])
global CountingClass = defclass(:CountingClass, [Class], [Pair(:counter, 0)])
global ColorMixin = defclass(:ColorMixin, [], [[:color, Pair(:reader, :get_color), Pair(:writer, :set_color!), Pair(:initform, "ola")]])


global Line = defclass(:Line, [Shape], [:from, :to])
global Circle = defclass(:Circle, [Shape], [:center, :radius])

global Screen = defclass(:Screen, [Device], [])
global Printer = defclass(:Printer, [Device], [])

global Foo = defclass(:Foo, [], [], metaclass=CountingClass)

global Bar = defclass(:Bar, [], [], metaclass=CountingClass)

global ColorMixin = defclass(:ColorMixin, [], [[:color, reader=get_color, writer=set_color!]])

global ColoredLine = defclass(:ColoredLine, [ColorMixin, Line], [])
global ColoredCircle = defclass(:ColoredCircle, [ColorMixin, Circle], [])

global ColoredPrinter = defclass(:ColoredPrinter, [Printer], [[ink=:black, reader=get_device_color, writer=_set_device_color!]])

global Person = defclass(:Person, [], [[:name, reader=get_name, writer=set_name!],
[:age, reader=get_age, writer=set_age!, initform=0],
[:friend, reader=get_friend, writer=set_friend!]],
metaclass=UndoableClass)

#=
function defgeneric(name::Symbol, args...)
    #@eval ($name)(args...) = nothing
    f = eval(Expr(:function, Expr(:call, name, args...), :nothing))
    eval(Expr(:(=), name, f))

    nao usar eval, quote ou uma Expr
    println("I entered a generic function.")
end

defgeneric(:add, :a, :b)

defgeneric(:print_object, :obj, :io)

function defmethod(name::Symbol, argtypes::Tuple, body::Expr)
    generic_function = getfield(Main, name)
    if !isa(generic_function, Function)
        error("'$name' not a function")
    end
    f = Expr(:function, Expr(:call, generic_function, argtypes...), body)
    eval(Meta.parse(string(f)))
end

# does not work, says a not defined
#defmethod(:add, (Int64, Int64), :(a+b))

#=
c2 = new(ComplexNumber, real=3, imag=4)
println(add(c1, c2))
=#