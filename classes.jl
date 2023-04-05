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
    class_precedence_list::Vector{class}
    #effective_slots::Dict{Symbol, Any}
    metaclass::Union{class, Nothing}

    function class(name::Symbol, direct_superclasses, direct_slots=Dict{Symbol, Any}(), class_precedence_list=[], metaclass=nothing)
        new(name, direct_superclasses, direct_slots, class_precedence_list, metaclass)
    end
end

struct multiMethod
    specializers::Vector{class}
    procedure::Vector{Any}
    generic_function::Symbol
end

struct genericFunction
    name::Symbol
    methods::Vector{multiMethod}
end

# global dictionary to keep track of instances
#instance_registry = Dict{Symbol, class}()
instance_registry = Vector{class}()

# root of class hierarchy
global Top = class(:Top, [], Dict())

# Object is a subclass of Top; all (regular) classes inherit from Object
global Object = class(:Object, [Top], Dict())
#class_registry[:Object] = Object

function defclass(name::Symbol, direct_superclasses, direct_slots; kwargs...)
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

    if haskey(kwargs, :metaclass)
        # a metaclass was received
        # name becames the metaclass name??
        new_classe = class(name, new_superclasses, slots_dict, [], kwargs[:metaclass])
    else
        new_classe = class(name, new_superclasses, slots_dict, [])
    end
    #class_registry[name] = new_classe
    return new_classe
end

#= in assignment is obj::Object
function print_object(obj::class, io::IO)
    println(io, "<$(class_name(class_of(obj))) $(string(objectid(obj), base=62))>")
end=#

function Base.copy(m::class)
    return class(getfield(m, :name), copy(getfield(m, :direct_superclasses)), copy(getfield(m, :direct_slots)), copy(getfield(m, :class_precedence_list)), getfield(m, :metaclass))
end

function allocate_instance(classe::class)
    instance = copy(classe)
    push!(instance_registry, instance)
    return instance
end

function compute_cpl(c::class)
    cpl = Vector{class}()
    queue = [c]
    visited = Set{class}(queue)
    while !isempty(queue)
        current = popfirst!(queue)
        push!(cpl, current)
        for superclass in current.direct_superclasses
            if(superclass != Object)
                if !(superclass in visited)
                    push!(queue, superclass)
                    push!(visited, superclass)
                end
            end
        end
    end
    # in case is a special metaClass?! TODO
    push!(cpl, Object)
    push!(cpl, Top)
    return cpl
end

function initialize(classe::class; kwargs...)
    for (slot, value) in getfield(classe, :direct_slots)
        if haskey(kwargs, slot)
            getfield(classe, :direct_slots)[slot] = kwargs[slot]
        end
    end
end

function new(classe::class; kwargs...)
    instance = allocate_instance(classe)
    initialize(instance; kwargs...)
    cpl = compute_cpl(classe)
    append!(getfield(instance, :class_precedence_list), cpl)
    return instance
end

function compute_slots(classe::class)
    all_slots = Vector{Symbol}()
    append!(all_slots, keys(getfield(classe, :direct_slots)))

    # search in superclasses for slots, TODO: in assignment says it should go to cpl, not direct_superclass
    if(!isempty(getfield(classe, :direct_superclasses)))
        for superclass in getfield(classe, :direct_superclasses)
            if superclass != Object
                append!(all_slots, keys(getfield(superclass, :direct_slots)))
            end
        end
    end
    return println(all_slots)
end

function Base.getproperty(classe::class, slot::Symbol)
    if slot == :slots
        if(classe == Class)
            return println(collect(fieldnames(class)))
        
        else # TODO: or GenericFunction or MultiMethod
            
            return compute_slots(classe)
        end
    end

    if slot == :direct_slots
        if isempty(keys(getfield(classe, :($slot))))
            return println([])
        else
            return println(keys(getfield(classe, :($slot))))
        end
    end

    if slot == :name
        return getfield(classe, :($slot))
    end

    if slot == :direct_superclasses
        if isdefined(classe, slot)
            classes = []
            for c in getfield(classe, :($slot))
                push!(classes, c)
            end
            return classes
        end
    end

    if slot == :class_precedence_list
        if isdefined(classe, slot)
            classes = []
            for c in getfield(classe, :($slot))
                push!(classes, c)
            end
            return classes
        end
    end

    # slot is a slot
    #search in superclasses for slots
    if (!isempty(getfield(classe, :direct_superclasses)))
        for superclass in getfield(classe, :direct_superclasses)
            if superclass != Object
                if (haskey(getfield(superclass, :direct_slots), slot))
                    return getfield(superclass, :direct_slots)[slot]
                end
            end
        end
    end

    if haskey(getfield(classe, :direct_slots), slot)
        return getfield(classe, :direct_slots)[slot]
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

function print_object(classe::class)
    println("<$(class_name(class_of(classe))) $(class_name(classe))>")
    return classe
end

global Class = defclass(:Class, [], [])

function class_name(classe::class) 
    classe.name
end

function class_slots(classe::class) 
    classe.slots
end

Class.name
Class.slots

class_name(Class)
class_slots(Class)


function class_direct_slots(classe::class) 
    classe.direct_slots
end

function class_cpl(classe::class) 
    classe.class_precedence_list
end

function class_direct_superclasses(classe::class) 
    classe.direct_superclasses
end

global A = defclass(:A, [], [])
global B = defclass(:B, [], [])
global C = defclass(:C, [], [])
global D = defclass(:D, [A, B], [])
global E = defclass(:E, [A, C], [])
global F = defclass(:F, [D, E], [])

compute_cpl(F)

global ComplexNumber = defclass(:ComplexNumber, [], [:real, :imag])

c1 = new(ComplexNumber, real=1, imag=2)
println(ComplexNumber)
c2 = new(ComplexNumber, real=3, imag=4)
println(ComplexNumber)

# built-in class
global BuiltInClass = class(:BuiltInClass, [Top], Dict())
_Int64 = new(BuiltInClass)
compute_cpl(_Int64) # wrong should be: builtinclass, top
_Float64 = new(BuiltInClass)
_String = new(BuiltInClass)

const BUILTIN_CLASSES = Dict(
    Int => _Int64,
    Float64 => _Float64,
    String => _String,
)

function class_of(x)
    if x == Class
        return Class
    elseif x isa class
        cpl = getfield(x, :class_precedence_list)
        if !isempty(cpl)
            return print_object(cpl[1])
        else
            return print_object(Class)
        end
    else
        special_name = get(BUILTIN_CLASSES, typeof(x), nothing)
        if special_name === nothing
            error("No class found for type $(typeof(x))")
        end
        cpl = getfield(special_name, :class_precedence_list)
        return cpl[1]
    end
end

ComplexNumber

class_of(c1) === ComplexNumber
class_of(c1)
class_of(class_of(c1))
class_of(class_of(c1)) === Class
class_of(class_of(class_of(c1))) === Class

class_of(1)
class_of("Foo")

for classe in instance_registry
    println(classe)
end

ComplexNumber.name
ComplexNumber.direct_superclasses == [Object]
ComplexNumber.direct_slots

class_name(ComplexNumber)
class_direct_superclasses(ComplexNumber)
class_direct_slots(ComplexNumber)
class_slots(ComplexNumber)

getproperty(c1, :real)
setproperty!(c1, :imag, -1)

c1.real
c1.imag
c1.imag += 3

global Circle = defclass(:Circle, [], [:center, :radius])
global ColorMixin = defclass(:ColorMixin, [], [:color])
global ColoredCircle = defclass(:ColoredCircle, [ColorMixin, Circle], [])
class_name(Circle)
class_direct_slots(Circle)
class_direct_slots(ColoredCircle)
class_slots(ColoredCircle)
class_direct_superclasses(ColoredCircle)

# class hierarchy
ColoredCircle.direct_superclasses
ans[1].direct_superclasses
ans[1].direct_superclasses
ans[1].direct_superclasses

global Foo = defclass(:Foo, [], [:a => 1, :b => 2])
global Bar = defclass(:Bar, [], [:b => 3, :c => 4])
global FooBar = defclass(:FooBar, [Foo, Bar], [:a => 5, :d => 6])
class_slots(FooBar)

foobar1 = new(FooBar)

foobar1.a
foobar1.b
foobar1.c
foobar1.d

global CountingClass = defclass(:CountingClass, [Class], [:counter => 0])

global Foo = defclass(:Foo, [], [], metaclass=CountingClass)
Foo.direct_superclasses
getfield(Foo, :metaclass)

global Bar = defclass(:Bar, [], [], metaclass=CountingClass)


#=function class_of(classe::class)
    return classe
end=#

global Shape = defclass(:Shape, [], [])
global Device = defclass(:Device, [], [])

#global CountingClass = defclass(:CountingClass, [Class], [counter=0])
#global CountingClass = defclass(:CountingClass, [Class], [Pair(:counter, 0)])

global ColorMixin = defclass(:ColorMixin, [], [[:color, Pair(:reader, :get_color), Pair(:writer, :set_color!), Pair(:initform, "ola")]])
global ColorMixin = defclass(:ColorMixin, [], [[:color, Pair(:reader, :get_color), Pair(:writer, :set_color!), Pair(:initform, "ola")]])

#global Foo = defclass(:Foo, [], [[:foo, :reader => :get_foo, :writer => :set_foo!, :initform => 123]])
global Foo = defclass(:Foo, [], [[:foo => 123, :reader => :get_foo, :writer => :set_foo!]])

global Line = defclass(:Line, [Shape], [:from, :to])
#global Circle = defclass(:Circle, [Shape], [:center, :radius])

global Screen = defclass(:Screen, [Device], [])
global Printer = defclass(:Printer, [Device], [])

#global ColorMixin = defclass(:ColorMixin, [], [[:color, reader=get_color, writer=set_color!]])

global ColoredLine = defclass(:ColoredLine, [ColorMixin, Line], [])
#global ColoredCircle = defclass(:ColoredCircle, [ColorMixin, Circle], [])

global ColoredPrinter = defclass(:ColoredPrinter, [Printer], [[ink=:black, reader=get_device_color, writer=_set_device_color!]])

global Person = defclass(:Person, [], [[:name, reader=get_name, writer=set_name!],
[:age, reader=get_age, writer=set_age!, initform=0],
[:friend, reader=get_friend, writer=set_friend!]],
metaclass=UndoableClass)

#global GenericFunction = defgeneric(:GenericFunction, [])
#global MultiMethod = defmethod([], [], )

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