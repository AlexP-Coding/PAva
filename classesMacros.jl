# Group 3
# Alexandra Rodrigues 95528
# Alexandra Pato 97375
# Miguel Encarnacao 105718
# Mafalda Cravo 105728

# ------ Julia's structs to reify classes, generic functions, methods and instances ------

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
    procedure::Function
    generic_function::Union{Symbol, Nothing}
end

struct genericFunction
    name::Symbol
    parameters::Vector{Symbol}
    methods::Vector{multiMethod}

    function genericFunction(name::Symbol, parameters, methods)
        new(name, parameters, methods)
    end
end

struct instanceWrap
    classtoinstance::Dict{Symbol, Any}
end

# ------ Global dictionaries to keep track of classes, instances and generic functions ------

# global dictionary to keep track of clases
class_registry = Dict{Symbol, class}()

# global dictionary to keep track of classes of instances
instance_registry_2 = Dict{instanceWrap, class}()

# global dictionary to keep track of generic functions
generic_registry = Dict{Symbol, genericFunction}()

# ------ Creation of Top, Object and BuiltInClass classes ------

global Top = class(:Top, [], Dict())

global Object = class(:Object, [Top], Dict())
class_registry[:Object] = Object

global BuiltInClass = class(:BuiltInClass, [Top], Dict())
class_registry[:BuiltInClass] = BuiltInClass

# ------ Creation of special classes that represent Julia's predefined types with BuiltInClass as metaclass ------

global _Int64 = class(:_Int64, [], Dict(), [], BuiltInClass)
class_registry[:_Int64] = _Int64
append!(getfield(_Int64, :class_precedence_list), [BuiltInClass, _Int64, Top])

global _Float64 = class(:_Float64, [], Dict(), [], BuiltInClass)
class_registry[:_Float64] = _Float64
append!(getfield(_Float64, :class_precedence_list), [BuiltInClass, _Float64, Top])

global _String = class(:_String, [], Dict(), [], BuiltInClass)
class_registry[:_String] = _String
append!(getfield(_String, :class_precedence_list), [BuiltInClass, _String, Top])

# ------ Function definitions ------

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
                    println("Stored a reader method")
                    #=@defgeneric get_name(o)
                    @defgeneric get_age(o)
                    @defgeneric get_friend(o)=#

                elseif :writer in transformed_option
                    println("Stored a writer method")
                    #=@defgeneric set_name!(o)
                    @defgeneric set_age!(o)
                    @defgeneric set_friend!(o)=#
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

function Base.copy(m::class)
    return class(getfield(m, :name), copy(getfield(m, :direct_superclasses)), copy(getfield(m, :direct_slots)), copy(getfield(m, :class_precedence_list)), getfield(m, :metaclass))
end

function allocate_instance(classe::class)
    # nao deve ser copy
    # estrutura que tem dicionario
    instance_classe = copy(classe)
    #slots_dict = Dict()
    slots_dict = getfield(instance_classe, :direct_slots)
    #for (slot, value) in getfield(instance_classe, :direct_slots)
    #    slots_dict[slot] = nothing
    #end
    instance = instanceWrap(slots_dict)
    #push!(instance_registry, instance)
    instance_registry_2[instance] = instance_classe
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
    if c == BuiltInClass
        return cpl
    end
    push!(cpl, Object)
    push!(cpl, Top)
    return cpl
end

function initialize(instance::instanceWrap; kwargs...)
    classe = instance_registry_2[instance]
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
            if haskey(getfield(instance, :classtoinstance), slot)
                #println(slot)
                #println(getfield(instance, :classtoinstance))
                getfield(instance, :classtoinstance)[slot] = kwargs[slot]
            end
        end
    end
    #println("instance_classe: ", classe)
end

function new(classe::class; kwargs...)
    instance = allocate_instance(classe)
    instance_classe = instance_registry_2[instance]
    #println("new_instance: ", instance)

    initialize(instance; kwargs...)
    cpl = compute_cpl(classe)
    append!(getfield(instance_classe, :class_precedence_list), cpl)
    
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
    #println(all_slots)
    return all_slots
end

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
    elseif slot == :procedure
        return getfield(method, :($slot))
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

function Base.getproperty(instance::instanceWrap, slot::Symbol)
    classe = instance_registry_2[instance]
    Base.getproperty(classe, slot)
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
            #println(classes)
            return classes
        end
    end

    if slot == :class_precedence_list
        return compute_cpl(classe)
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

function Base.setproperty!(instance::instanceWrap, slot::Symbol, value::Any)
    classe = instance_registry_2[instance]
    getfield(instance, :classtoinstance)[slot] = value
    Base.setproperty!(classe, slot, value)
end

function Base.setproperty!(classe::class, slot::Symbol, value::Any)
    if haskey(getfield(classe, :direct_slots), slot)
        getfield(classe, :direct_slots)[slot] = value
    else
        error("$(classe.name) does not have slot $slot")
    end
    return getfield(classe, :direct_slots)[slot]
end

function class_of(x)
    #println(x)
    if x == Class
        #println("entrei1")
        return Class
    elseif x isa instanceWrap
        #println("entrei2")
        classe = instance_registry_2[x]
        return class_of(classe)
    elseif x isa class
        #println("entrei3")
        cpl = getfield(x, :class_precedence_list)
        # println(cpl(getfield(x, :class_precedence_list)))
        #println(cpl)
        # if length(cpl) != 0
        if !isempty(cpl)
            # x2 = cpl[1]
            # println(string("cpl[1] x2",x2))
            return cpl[1]
        elseif getfield(x, :metaclass) !== nothing
            return getfield(x, :metaclass)
        else
            # println("cpl is empty")
            return Class
        end
        # end
    elseif x isa genericFunction
        #println("entrei4")
        return GenericFunction
    elseif x isa multiMethod
        #println("entrei4")
        return MultiMethod
    elseif x isa Int64
        return _Int64
    elseif x isa Float64
        return _Float64
    elseif x isa String
        return _String
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

# ------ Creation of Class class ------

global Class = defclass(:Class, [], [])
class_registry[:Class] = Class

# ------ Function definitions for printing objects ------

function Base.show(io::IO, classe::class)
    return print_object(classe, io)
end

function print_object(classe::class, io::IO)
    if getfield(classe, :metaclass) !== nothing
        #println(class_name(classe))
        return print(io, "<$(class_name(getfield(classe, :metaclass))) $(class_name(classe))>")
    #elseif getfield(classe, :name) == getfield(BuiltInClass, :name)
        #println("entrei1")
        #return println("<$(class_name(class_of(classe))) $(class_name(classe))>")
    else
        #println("entrei2")
        return print(io, "<$(class_name(class_of(classe))) $(class_name(classe))>")
    end
end

function Base.show(io::IO, instance::instanceWrap)
    # println("show")
    return print_object(instance, io)
end

function print_object(instance::instanceWrap, io::IO)
    print(io,"<$(class_name(class_of(instance))) $(string(objectid(instance), base=62))>")
end

function Base.show(io::IO, method::multiMethod)
    # println("show")
    return print_object(method, io)
end

function print_object(method::multiMethod, io::IO)
    specializers = [class_name(spec) for spec in method_specializers(method)]
    specializers_rev = reverse!(specializers)
    spec_tuple = tuple(specializers_rev...)
    if method.generic_function !== nothing
        return print(io,"<MultiMethod $(generic_name(method_generic_function(method)))$(spec_tuple)>") # its printing :bla, FIX
    else
        return print(io,"<MultiMethod>")
    end
end

function Base.show(io::IO, generic::genericFunction)
    # println("show")
    return print_object(generic, io)
end

function print_object(generic::genericFunction, io::IO)
    if generic_methods(generic) !== nothing
        return print(io,"<$(generic_name(class_of(generic))) $(generic_name(generic)) with $(length(generic_methods(generic))) methods>")
    else
        return print(io,"<$(generic_name(class_of(generic))) $(generic_name(generic)) with 0 methods>")
    end
end

# ------ Macro definition for defclass ------

macro defclass(expr...)
    #=dump(expr)
    println(expr[3])
    for expr in expr[3].args
        println(expr)
        if length(expr) == 4

        end
    end=#
    quote
        global $(esc(expr[1])) = defclass($expr[1], $(expr[2].args), $(expr[3:end]))
    end
end

@defclass(Foo, [], [[foo=123, reader=get_foo, writer=set_foo!]])

# ----------------------------- Generic functions ---------------------------------

function defgeneric(name::Symbol, parameters)
    #println("I entered a generic function.")
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

# macro definition for @defgeneric
macro defgeneric(expr...)
    quote
        $(esc(expr[1].args[1])) = defgeneric($expr[1].args[1], $expr[1].args[2:end])
    end
end

# ----------------------------- Multi method ---------------------------------

function method_generic_function(method::multiMethod)
    method.generic_function
end

function method_specializers(method::multiMethod)
    method.specializers
end

global MultiMethod = multiMethod(Dict(), () -> (), nothing)

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

    # add method to generic function
    # TODO: ver se já existe na generic function aquele metodo, para nao ter repetidos
    push!(getfield(generic, :methods), new_method)

    return new_method
end

# macro definition for @defmethod
macro defmethod(expr...)
    fun_args = []
    fun_args_specializers = []
    args_types = expr[1].args[1].args[2:end]
    args = []
    for arg in args_types
        if isa(arg, Symbol)
            push!(fun_args, arg)
            push!(args, arg)
            push!(fun_args_specializers, Top)
        else
            push!(fun_args, arg.args[1])
            push!(args, arg.args[1])
            push!(fun_args_specializers, class_registry[arg.args[2]])
        end
    end
    body = expr[1].args[2]
    #println("body: ", expr[1].args[2].args[2])

    quote
        defmethod($expr[1].args[1].args[1], $fun_args, $fun_args_specializers, ($(args...), next_methods, args) -> $body)
    end
end

# ------ Generic function call ------

(x::genericFunction)(args...) = generic_call(x, args)
(x::multiMethod)(args...) = x.procedure(args...)

function generic_call(generic::genericFunction, args)
    @assert length(args) == length(getfield(generic, :parameters))

    selected_methods = select_applicable_methods(generic, args)
    #println("selected_methods: ", selected_methods)

    if !no_applicable_method(generic, selected_methods, args)
        #println("Tem!")
        return selected_methods[1].procedure(args..., call_next_method(selected_methods[2:end], args), args)
    else
        #println("Nao tem!")
        return
    end
end

function call_next_method(next_methods, args)
    for idx in 1:length(next_methods)
        next_methods[idx](args..., next_methods[idx+1:end], args)
    end
end

function select_applicable_methods(generic, args)
    #applicable_methods = []
    methods = generic_methods(generic)

    #println("methods: ", generic.methods)

    argtypes = get_types_in_symbol(args)
    #println(argtypes)
    # search in the vector for methods that match the argtypes
    #println("generic methods: ", generic.methods)
    applicable_methods = get_applicable_methods(generic.methods, argtypes)
    
    #println("not sorted: ", applicable_methods)
    sorted_methods = applicable_methods
    sort_methods(sorted_methods, argtypes)
    #println("sorted: ", sorted_methods)

    return sorted_methods
end

function compare_cpl(type1, type2, cpl)
    idx1 = findfirst(x -> x == type1, cpl)
    idx2 = findfirst(x -> x == type2, cpl)
    #println("idx1: ", idx1)
    #println("idx2: ", idx2)
    if idx1 < idx2
        # first type occurs before the second type in the list
        return true
    elseif idx1 > idx2
        # second type occurs before the first type in the list
        return false
    else
        # are the same type
        return nothing
    end
end

function comparemethods(m1, m2, argtypes)
    args1 = reverse!(method_specializers(m1))
    #println("args1: ", args1)
    args2 = reverse!(method_specializers(m2))
    #println("args2: ", args2)

    cpl_list = [getfield(arg, :class_precedence_list) for arg in argtypes]
    #println("cpl_list: ", cpl_list)

    for (i, (arg1, arg2)) in enumerate(zip(args1, args2))
        #println("arg1: ", arg1)
        #println("arg2: ", arg2)
        #println("cpl_list[i]: ", cpl_list[i])
        if compare_cpl(arg1, arg2, cpl_list[i]) == true
            return true
        elseif compare_cpl(arg1, arg2, cpl_list[i]) == false
            return false
        end
    end
    return false
end

function sort_methods(applicable_methods, argtypes)
    sort!(applicable_methods, lt=(m1, m2) -> comparemethods(m1, m2, argtypes))
end

function get_applicable_methods(methods, argtypes)
    applicable_methods = []
    #println("methods: ", methods)
    for method in methods
        if is_same_type(method_specializers(method), argtypes)
            push!(applicable_methods, method)
        end
    end
    applicable_methods
end

function is_same_type(method, argtypes)
    #println("method: ", method)
    method = reverse!(method)
    for i in 1:length(method)
        #println("method: ", method[i])
        #println("arg: ", argtypes[i])
        #println("cpl: ", getfield(argtypes[i], :class_precedence_list))
        if !(method[i] in getfield(argtypes[i], :class_precedence_list))
            #println("entrei no false")
            return false
        end
        #println("nao entrei no if")
    end
    true
end

function get_types_in_symbol(args)
    return arg_types = map(arg -> ( if arg isa Int64 
                                        return _Int64
                                    elseif arg isa Float64
                                        return _Float64
                                    elseif arg isa String
                                        return _String
                                    else 
                                        return instance_registry_2[arg]
                                    end), args)
    #println("arg types function: ", arg_types)
end

function no_applicable_method(generic, selected_methods, args)
    if length(selected_methods) > 0
        return false
    else
        println("ERROR: No applicable method for function $(generic_name(generic)) with arguments $(args)")
        return true
    end
end

# --------------------- To test -----------------------------------------------------------

@defclass(ComplexNumber, [], [real, imag])

c1 = new(ComplexNumber, real=1, imag=2)

getproperty(c1, :real)
setproperty!(c1, :imag, -1)

c1.real
c1.imag
c1.imag += 3

@defgeneric add(a, b)
@defmethod add(a::ComplexNumber, b::ComplexNumber) = new(ComplexNumber, real=(a.real + b.real), imag=(a.imag + b.imag))

#@defgeneric print_object(obj, io) TODO

c2 = new(ComplexNumber, real=3, imag=4)

add(c1, c2)

class_of(c1) === ComplexNumber
ComplexNumber.direct_slots
class_of(class_of(c1)) === Class
class_of(class_of(class_of(c1))) === Class

Class.name
Class.slots
class_name(Class)
class_slots(Class)

ComplexNumber.name
ComplexNumber.direct_superclasses == [Object]

add
add.name
generic_name(add)
add.parameters
generic_parameters(add)
add.methods
generic_methods(add)
class_of(add) === GenericFunction
GenericFunction.slots

class_of(add.methods[1]) === MultiMethod
MultiMethod.slots
add.methods[1]
add.methods[1].specializers
add.methods[1].generic_function === add

@defclass(UndoableClass, [Class], [])

@defclass(Person, [],
[[name, reader=get_name, writer=set_name!],
[age, reader=get_age, writer=set_age!, initform=0],
[friend, reader=get_friend, writer=set_friend!]],
metaclass=UndoableClass)

Person
class_of(Person)
class_of(class_of(Person))

add(123, 456)

@defclass(Circle, [], [center, radius])
@defclass(ColorMixin, [], [color])
@defclass(ColoredCircle, [ColorMixin, Circle], [])

# class hierarchy
ColoredCircle.direct_superclasses
ans[1].direct_superclasses
ans[1].direct_superclasses
ans[1].direct_superclasses

@defclass(A, [], [])
@defclass(B, [], [])
@defclass(C, [], [])
@defclass(D, [A, B], [])
@defclass(E, [A, C], [])
@defclass(F, [D, E], [])

compute_cpl(F)

class_of(1)
class_of("Foo")

@defmethod add(a::_Int64, b::_Int64) = a + b
@defmethod add(a::_String, b::_String) = a * b

add(1, 3)
add("Foo", "Bar")

class_name(Circle)
class_direct_slots(Circle)
class_direct_slots(ColoredCircle)
class_slots(ColoredCircle)
class_direct_superclasses(ColoredCircle)
class_cpl(ColoredCircle)
#generic_methods(draw)
#method_specializers(generic_methods(draw)[1])

@defclass(Foo, [], [a=1, b=2])
@defclass(Bar, [], [b=3, c=4])
@defclass(FooBar, [Foo, Bar], [a=5, d=6])
class_slots(FooBar)

foobar1 = new(FooBar)

foobar1.a
foobar1.b
foobar1.c
foobar1.d

@defclass(FlavorsClass, [Class], [])

@defclass(A, [], [], metaclass=FlavorsClass)
@defclass(B, [], [], metaclass=FlavorsClass)
@defclass(C, [], [], metaclass=FlavorsClass)
@defclass(D, [A, B], [], metaclass=FlavorsClass)
@defclass(E, [A, C], [], metaclass=FlavorsClass)
@defclass(F, [D, E], [], metaclass=FlavorsClass)

compute_cpl(F)

@defclass(Shape, [], [])
@defclass(Device, [], [])

@defgeneric draw(shape, device)

@defclass(Line, [Shape], [from, to])
@defclass(Circle, [Shape], [center, radius])
@defclass(Screen, [Device], [])
@defclass(Printer, [Device], [])

@defmethod draw(shape::Line, device::Screen) = println("Drawing a Line on Screen")
@defmethod draw(shape::Circle, device::Screen) = println("Drawing a Circle on Screen")
@defmethod draw(shape::Line, device::Printer) = println("Drawing a Line on Printer")
@defmethod draw(shape::Circle, device::Printer) = println("Drawing a Circle on Printer")

# to test the order of methods
@defmethod draw(shape::Line, device::Screen) = println("Drawing a Line on Screen")
@defmethod draw(shape::Line, device::Device) = println("Drawing a Line on Device")
@defmethod draw(shape::Shape, device::Device) = println("Drawing a Shape on Device")
@defmethod draw(shape::Shape, device::Screen) = println("Drawing a Shape on Screen")

draw(new(Line), new(Screen))

let devices = [new(Screen), new(Printer)],
    shapes = [new(Line), new(Circle)]
    for device in devices
        for shape in shapes
            draw(shape, device)
        end
    end
end

@defclass(CountingClass, [Class], [counter=0])

@defclass(Foo, [], [], metaclass=CountingClass)

@defclass(ColorMixin, [], [[color, reader=get_color, writer=set_color!, initform="rosa"]])
