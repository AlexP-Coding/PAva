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
    metaclass::Union{class, Nothing}

    function class(name::Symbol, direct_superclasses, direct_slots=Dict{Symbol, Any}(), class_precedence_list=[], metaclass=nothing)
        new(name, direct_superclasses, direct_slots, class_precedence_list, metaclass)
    end
end

struct multiMethod
    specializers::Dict{Symbol, class}
    procedure::Union{Expr, Nothing}
    generic_function::Union{Symbol, Nothing}

    function multiMethod(specializers, procedure, generic_function)
        new(specializers, procedure, generic_function)
    end
end

struct genericFunction
    name::Symbol
    parameters::Vector{Symbol}
    methods::Vector{multiMethod}

    function genericFunction(name::Symbol, parameters, methods)
        new(name, parameters, methods)
    end
end

# global dictionary to keep track of clases
class_registry = Dict{Symbol, class}()
# global dictionary to keep track of instances
instance_registry = Vector{class}()
# global dictionary to keep track of generic functions
generic_registry = Dict{Symbol, genericFunction}()

# root of class hierarchy
global Top = class(:Top, [], Dict())

# Object is a subclass of Top; all (regular) classes inherit from Object
global Object = class(:Object, [Top], Dict())
class_registry[:Object] = Object

function defclass(name::Symbol, direct_superclasses, direct_slots; kwargs...)
    #slots_dict = Dict(slot => nothing for slot in direct_slots)
    #println(direct_slots)
    slots_dict = Dict()

    #println("name: ", name)
    #dump(direct_slots)

    if length(direct_slots) == 2
        metaclass = direct_slots[2]
        new_direct_slots = direct_slots[1].args
    elseif length(direct_slots) == 1
        new_direct_slots = direct_slots[1].args
    elseif length(direct_slots) == 0
        new_direct_slots = direct_slots
    end

    for slot in new_direct_slots
        #dump(slot)
        for superclass in direct_superclasses
            superclassClass = class_registry[superclass]
            for super_slot in getfield(superclassClass, :direct_slots)
                if slot == super_slot.first
                    error("Duplicated slots!")
                end
            end
        end
        # only slot name is provided
        if isa(slot, Symbol)
            #println("Is a symbol")
            slots_dict[slot] = nothing
        # slot name includes reader, writer or initform
        elseif slot.head === :vect
            #println("Is a Vector")
            slot_name = slot.args[1]
            #slot_name = slot[1]
            #println(slot_name)
            slot_options = slot.args[2:end]
            #println(slot_options)

            if isa(slot_name, Symbol)
                #println("Vector slot name is a symbol")
                #slots_dict[slot] = direct_slots[slot]
                slots_dict[slot_name] = nothing
            else
                #println("Vector with Name and Value")
                slots_dict[slot_name.args[1]] = slot_name.args[2]
            end
            
            for option in slot_options
                transformed_option = Pair(option.args[1], option.args[2])
                #if haskey(slot_options, :initform)
                if :initform in transformed_option
                    #println("Vector slot name as initform")
                    #slots_dict[slot_name] = slot_options[:initform]
                    slots_dict[slot_name] = transformed_option.second
                #if haskey(slot_options, :reader)

                # isso acho que passa para a macro
                elseif :reader in transformed_option
                    println("Created a reader method")
        
                elseif :writer in transformed_option
                    println("Created a writer method")
                end
            end

        # slot name with iniform value are provided
        elseif isa(slot.head, Symbol)
            #println("Name and Value")
            #slots_dict[slot] = direct_slots[slot]
            #doing it like a pair
            transformed_slot = Pair(slot.args[1], slot.args[2])
            slots_dict[transformed_slot.first] = transformed_slot.second
        end
    end
    
    
    #slots_dict = Dict(direct_slots[1] => nothing for slot in direct_slots)
    
    new_superclasses = Vector{class}()
    
    # all classes inherit, directly or indirectly from Object class
    for classe in direct_superclasses
        class_obj = class_registry[classe]
        push!(new_superclasses, class_obj)
    end

    if !(Object in direct_superclasses)
        class_objet = class_registry[:Object]
        push!(new_superclasses, class_objet)
    end

    if length(direct_slots) == 2
        # a metaclass was received
        # name becames the metaclass name??
        class_objet = class_registry[metaclass.args[2]]
        new_classe = class(name, new_superclasses, slots_dict, [], class_objet)
    else
        new_classe = class(name, new_superclasses, slots_dict, [])
    end
    #println("estou aqui")
    class_registry[name] = new_classe
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
        for superclass in getfield(current, :direct_superclasses)
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
    for super_class in getfield(classe, :direct_superclasses)
        for super_slot in getfield(super_class, :direct_slots)
            if haskey(kwargs, super_slot.first)
                getfield(super_class, :direct_slots)[super_slot.first] = kwargs[super_slot.first]
            end
        end
    end
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
    append!(getfield(instance, :class_precedence_list), cpl) #acho que isto nao esta
    return instance
end

function compute_slots(classe:: class)
    all_slots = Vector{Symbol}()
    append!(all_slots, keys(getfield(classe, :direct_slots)))
    cpl = compute_cpl(classe)
    #println("Printing CPL:")
    #println(cpl)

    for superclass in cpl
        #println(superclass)
        sc_name = getfield(superclass, :name)
        #println(sc_name)
        if sc_name != Object && sc_name != Top && sc_name != getfield(classe, :name)
            #println(sc_name in all_slots)
            sc_keys = keys(getfield(superclass, :direct_slots))
            for key in sc_keys
                #if !(key in keys(getfield(classe, :direct_slots)))
                    append!(all_slots, [key])
                #end
            end
        end
    end

    #println("Printing all slots:")
    println(all_slots)
    return all_slots
end

#global Foo = defclass(:Foo, [], [:a => 2, :b => 9])
#global Bar = defclass(:Bar, [], [:c => 3, :d => 4])
#global FooBar = defclass(:FooBar, [Foo, Bar], [:a =>5, :f => 6])
#compute_slots(FooBar)

function Base.getproperty(method::multiMethod, slot::Symbol)
    if slot == :slots
        return println(collect(fieldnames(multiMethod)))
    elseif slot == :generic_function
        if getfield(method, :($slot)) === nothing
            return nothing
        else
            generic = generic_registry[getfield(method, :($slot))]
            return generic
        end
    elseif slot == :specializers
        return collect(values(getfield(method, :specializers)))
    end
end

function Base.getproperty(generic::genericFunction, slot::Symbol)
    if slot == :slots
        return println(collect(fieldnames(genericFunction)))
    elseif slot == :name
        return getfield(generic, :($slot))
    elseif slot == :methods # we can receive method[1]
        return getfield(generic, :($slot))
    elseif slot == :parameters
        return println(getfield(generic, :($slot)))
    end
end

function Base.getproperty(classe::class, slot::Symbol)
    if slot == :slots
        if(classe == Class)
            return println(collect(fieldnames(class)))
        else
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
    if getfield(classe, :metaclass) !== nothing
        return println("<$(class_name(getfield(classe, :metaclass))) $(class_name(classe))>")
    else
        return println("<$(class_name(class_of(classe))) $(class_name(classe))>")
    end
end

function Base.show(io::IO, classe::class)
    # println("show")
    return print_object(classe)
end

function Base.show(io::IO, method::multiMethod)
    # println("show")
    return print_object(method)
end

function print_object(method::multiMethod)
    specializers = [class_name(spec) for spec in method_specializers(method)]
    spec_tuple = tuple(specializers...)
    if method.generic_function !== nothing
        return println("<MultiMethod $(generic_name(method_generic_function(method)))$(spec_tuple)>") # its printing :bla, FIX
    else
        return println("<MultiMethod>")
    end
end

function Base.show(io::IO, generic::genericFunction)
    # println("show")
    return print_object(generic)
end

function print_object(generic::genericFunction)
    if generic_methods(generic) !== nothing
        return println("<$(generic_name(class_of(generic))) $(generic_name(generic)) with $(length(generic_methods(generic))) methods>")
    else
        return println("<$(generic_name(class_of(generic))) $(generic_name(generic)) with 0 methods>")
    end
end

function class_of(x)
    # println("inside class_of")
    if x == Class
        return Class
    elseif x isa class
        cpl = getfield(x, :class_precedence_list)
        # println(cpl(getfield(x, :class_precedence_list)))
        # println(cpl)
        # if length(cpl) != 0
        if !isempty(cpl)
            # x2 = cpl[1]
            # println(string("cpl[1] x2",x2))
            return cpl[1]
        else
            # println("cpl is empty")
            return Class
        end
        # end
    elseif x isa genericFunction
        return GenericFunction
    else
        special_name = get(BUILTIN_CLASSES, typeof(x), nothing)
        if special_name === nothing
            error("No class found for type $(typeof(x))")
        end
        cpl = getfield(special_name, :class_precedence_list)
        return cpl[1]
    end
end

function class_name(classe::class) 
    getfield(classe, :name)
end

function class_slots(classe::class) 
    classe.slots
end

function class_direct_slots(classe::class) 
    classe.direct_slots
end

function class_cpl(classe::class) 
    classe.class_precedence_list
end

function class_direct_superclasses(classe::class) 
    classe.direct_superclasses
end

macro defclass(expr...)
    println(expr[1])
    #dump(expr)
    quote
        global $(esc(expr[1])) = defclass($expr[1], $(expr[2].args), $(expr[3:end]))
    end
end

global Class = defclass(:Class, [], [])
class_registry[:Class] = Class

Class.name
Class.slots

class_name(Class)
class_slots(Class)

# ----------------------------- generic functions ---------------------------------

function defgeneric(name::Symbol, parameters)
    println("I entered a generic function.")
    new_generic = genericFunction(name, parameters, [])
    generic_registry[name] = new_generic
    return new_generic
end

function generic_name(generic::genericFunction)
    getfield(generic, :name)
end

function generic_parameters(generic::genericFunction)
    generic.parameters
end

function generic_methods(generic::genericFunction)
    generic.methods
end

global GenericFunction = genericFunction(:GenericFunction, [], [])
GenericFunction.slots

global add = defgeneric(:add, [:a, :b])

add
class_of(add) === GenericFunction

add.name
generic_name(add)
add.parameters
generic_parameters(add)
add.methods
generic_methods(add)

#=macro defgeneric(expr...)
    quote
        global $(expr[1].args[1]) = defgeneric($expr[1].args[1], $expr[1].args[2:end])
    end
end=#

#@defgeneric add2(a,b)

# macro definition for @defgeneric
macro defgeneric(expr...)
    # dump(expr)
    # for arg in expr[1].args
    #     println("arg: ", arg)
    # end
    quote
        # println($expr[1].args)
        # println("name: ", $expr[1].args[1])
        # for arg in $expr[1].args[2:end]
        #     println("arg: ", arg)
        # end
        # println($expr[1].args[1])
        # println($expr[1].args[2:end])

        global $(expr[1].args[1]) = defgeneric($expr[1].args[1], $expr[1].args[2:end])
    end
end

# @defgeneric tests
@defgeneric add2(a,b)

add2.name
generic_name(add2)
add2.parameters
generic_parameters(add2)
add2.methods
generic_methods(add2)

# ----------------------------- methods ---------------------------------

function method_generic_function(method::multiMethod)
    method.generic_function
end

function method_specializers(method::multiMethod)
    method.specializers
end

global MultiMethod = multiMethod(Dict(), nothing, nothing)
MultiMethod.slots

function defmethod(generic_function::Symbol, parameters, specializers, procedure)
    #if the corresponding generic function does not exist, creates
    if !(haskey(generic_registry, generic_function))
        generic = defgeneric(generic_function, parameters)
    else
        #method should have the same parameters as corresponding generic function
        generic = generic_registry[generic_function]

        if !(getfield(generic, :parameters) == parameters)
            error("method does not have same parameters as $(generic.name)")
        end
    end

    specializers_dict = Dict{Symbol, class}()

    for (p, s) in zip(parameters, specializers)
        specializers_dict[p] = s
    end

    new_method = multiMethod(specializers_dict, procedure, generic_function)

    #add method to generic function
    push!(getfield(generic, :methods), new_method)

    return new_method
end

defmethod(:add, [:a, :b], [ComplexNumber, ComplexNumber], :(new(ComplexNumber, real=(a.real + b.real), imag=(a.imag + b.imag))))

add.methods[1]
add.methods[1].generic_function === add
add.methods[1].specializers


# macro definition for @defmethod
macro defmethod(expr...)
    # dump(expr)
    # println("generic_function: ", expr[1].args[1].args[1])
    # # println("parameters: ", expr[1].args[1].args[2:end])
    # # println("specializers: ", expr[1].args[1].args[2].args[2])
    # println("procedure: ", expr[1].args[2].args[2])

    fun_args = []
    fun_args_specializers = []
    for arg in expr[1].args[1].args[2:end]
        # println("arg: ", arg.args[1])
        # println("specializer: ", arg.args[2])
        push!(fun_args, arg.args[1])
        push!(fun_args_specializers, class_registry[arg.args[2]])
    end
    # println(fun_args)
    # println(fun_args_specializers)

    quote
        defmethod($expr[1].args[1].args[1], $fun_args, $fun_args_specializers, $expr[1].args[2].args[2])
    end
end

# tests for @defmethod
@defclass(ComplexNumber, [], [real, imag])

@defmethod add2(a::ComplexNumber, b::ComplexNumber) = new(ComplexNumber, real=(a.real + b.real), imag=(a.imag + b.imag))


# example on how to access different parts of the expression tree
macro test(expr...)
    dump(expr)
    println("fun_name: ", expr[1].args[1].args[1])
    println("fun_args: ", expr[1].args[1].args[2:end])
    println("fun_call: ", expr[1].args[2].args[2].args[1])
    println("fun_call_args: ", expr[1].args[2].args[2].args[2])
end

@test fun_name(fun_arg1, fun_arg2) = fun_call(fun_call_args)
# --

# --------------------- To test after macros -----------------------------------------------------------

@defclass(ComplexNumber, [], [real, imag])

c1 = new(ComplexNumber, real=1, imag=2)

getproperty(c1, :real)
setproperty!(c1, :imag, -1)

c1.real
c1.imag
c1.imag += 3

class_of(c1) === ComplexNumber
ComplexNumber.direct_slots

class_of(class_of(c1)) === Class
class_of(class_of(class_of(c1))) === Class

Class.slots
ComplexNumber.name
ComplexNumber.direct_superclasses == [Object]

@defclass(CountingClass, [Class], [counter=0])

@defclass(Foo, [], [], metaclass=CountingClass)

@defclass(ColorMixin, [], [[color, reader=get_color, writer=set_color!, initform="rosa"]])

@defclass(Foo, [], [[foo=123, reader=get_foo, writer=set_foo!]])

@defclass(A, [], [], metaclass=ComplexNumber)
@defclass(B, [], [], metaclass=ComplexNumber)
@defclass(C, [], [], metaclass=ComplexNumber)
@defclass(D, [A, B], [], metaclass=ComplexNumber)
@defclass(E, [A, C], [], metaclass=ComplexNumber)
@defclass(F, [D, E], [], metaclass=ComplexNumber)

compute_cpl(F)

@defclass(A, [], [])
@defclass(B, [], [])
@defclass(C, [], [])
@defclass(D, [A, B], [])
@defclass(E, [A, C], [])
@defclass(F, [D, E], [])

compute_cpl(F)

@defclass(Circle, [], [center, radius])
@defclass(ColorMixin, [], [color])
@defclass(ColoredCircle, [ColorMixin, Circle], [])
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

@defclass(Foo, [], [a=1, b=2])
@defclass(Bar, [], [b=3, c=4])
@defclass(FooBar, [Foo, Bar], [a=5, d=6])
class_slots(FooBar)

foobar1 = new(FooBar)

foobar1.a
foobar1.b
foobar1.c
foobar1.d

# --------------------- To test before macros -----------------------------------------------------------

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

# function Base.show(io::IO, classes::Vector{class})
# println("show vec")
# end

global A = defclass(:A, [], [], metaclass=ComplexNumber)
global B = defclass(:B, [], [], metaclass=ComplexNumber)
global C = defclass(:C, [], [], metaclass=ComplexNumber)
global D = defclass(:D, [A, B], [], metaclass=ComplexNumber)
global E = defclass(:E, [A, C], [], metaclass=ComplexNumber)
global F = defclass(:F, [D, E], [], metaclass=ComplexNumber)

compute_cpl(F)

global A = defclass(:A, [], [])
global B = defclass(:B, [], [])
global C = defclass(:C, [], [])
global D = defclass(:D, [A, B], [])
global E = defclass(:E, [A, C], [])
global F = defclass(:F, [D, E], [])

compute_cpl(F)

println(class_of(F))

println("hello")
print_object(c1)

println("ddnsdfhello")
println(ComplexNumber)

class_of(c1) === ComplexNumber

println("hello")
println(class_of(c1))
println("hello")
class_of(class_of(class_of(c1)))
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
global CountingClass = defclass(:CountingClass, [Class], [Pair(:counter, 0)])

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

global Person = defclass(:Person, [], [:nome])
global Student = defclass(:Student, [Person], [:id])

s1 = new(Student, nome="Joao", id=1)
getproperty(s1, :nome)
println(s1)
s1.nome
s1.id

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