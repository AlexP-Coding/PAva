# Group 3
# Alexandra Rodrigues 95528
# Alexandra Pato 97375
# Miguel Encarnacao 105718
# Mafalda Cravo 105728

include("structures/struct_collection.jl")

# global dictionary to keep track of classes
class_registry = Dict{Symbol, class}()

# global dictionary to keep track of classes of instances
instance_registry_2 = Dict{instanceWrap, class}()

# global dictionary to keep track of generic functions
generic_registry = Dict{Symbol, genericFunction}()

# ------ Creation of Top, Object and BuiltInClass classes ------

global Top = class(:Top, [], Dict())
class_registry[:Top] = Top

global Object = class(:Object, [Top], Dict())
class_registry[:Object] = Object

global BuiltInClass = class(:BuiltInClass, [Top], Dict())
class_registry[:BuiltInClass] = BuiltInClass
append!(getfield(BuiltInClass, :class_precedence_list), [BuiltInClass, Top])

# ------ Creation of class Class ------

global Class = class(:Class, [], Dict())
class_registry[:Class] = Class
append!(getfield(Class, :class_precedence_list), [Class, Object, Top])

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

global _IO = class(:_IO, [], Dict(), [], BuiltInClass)
class_registry[:_IO] = _IO
append!(getfield(_IO, :class_precedence_list), [BuiltInClass, _IO, Top])

# ----------------------------- Generic functions ---------------------------------

function defgeneric(name::Symbol, parameters)
    new_generic = genericFunction(name, parameters, [])
    generic_registry[name] = new_generic
    return new_generic
end

global GenericFunction = genericFunction(:GenericFunction, [], [])
generic_registry[:GenericFunction] = GenericFunction

# macro definition for @defgeneric
macro defgeneric(expr...)
    quote
        $(esc(expr[1].args[1])) = defgeneric($expr[1].args[1], $expr[1].args[2:end])
    end
end

# ------ Introspetion of generic functions ------

generic_name(generic::genericFunction) = getfield(generic, :name)

generic_parameters(generic::genericFunction) = generic.parameters
   
generic_methods(generic::genericFunction) = generic.methods

# ----------------------------- Multi method ---------------------------------

global MultiMethod = multiMethod(Dict(), () -> (), :GenericFunction)

function defmethod(generic_function::Symbol, parameters, specializers, procedure)
    #if the corresponding generic function does not exist, creates
    specializers_dict = Dict{Symbol, class}()

    for (p, s) in zip(parameters, specializers)
        specializers_dict[p] = s
    end

    new_method = multiMethod(specializers_dict, procedure, generic_function)

    #method should have the same parameters as corresponding generic function
    generic = generic_registry[generic_function]

    if !(length(getfield(generic, :parameters)) == length(parameters))
        error("method does not have same parameters as $(generic.name)")
    end

    # add method to generic function
    # TODO: ver se já existe na generic function aquele metodo, para nao ter repetidos
    push!(getfield(generic, :methods), new_method)

    return new_method
end

# macro definition for @defmethod
macro defmethod(expr...)
    args_types = expr[1].args[1].args[2:end]
    args_specializers = []
    args = []
    
    for arg in args_types
        if isa(arg, Symbol)
            push!(args, arg)
            push!(args_specializers, Top)
        else
            push!(args, arg.args[1])
            push!(args_specializers, class_registry[arg.args[2]])
        end
    end
    for arg_spec in args_specializers
        if arg_spec == Top
            reverse!(args_specializers)
        end
    end

    body = expr[1].args[2]
    name = [expr[1].args[1].args[1]]

    generic_args = vcat(name, args)
    ex = Expr(:call, generic_args...)
    
    quote
        if !(haskey(generic_registry, $expr[1].args[1].args[1]))
            @defgeneric $(ex)
        end
        defmethod($expr[1].args[1].args[1], $args, $args_specializers, ($(args...), next_methods, args) -> $body)
    end
end

# ------ Introspetion of methods ------

method_generic_function(method::multiMethod) = method.generic_function
   
method_specializers(method::multiMethod) = reverse!(method.specializers)

# ------ Function definitions ------

function defclass(name::Symbol, direct_superclasses, direct_slots; kwargs...)
    #slots_dict = Dict(slot => nothing for slot in direct_slots)
    slots_dict = Dict()
    if length(direct_slots) == 2
        metaclass = direct_slots[2]
        new_direct_slots = direct_slots[1].args
    elseif length(direct_slots) == 1
        new_direct_slots = direct_slots[1].args
    elseif length(direct_slots) == 0
        new_direct_slots = direct_slots
    end

    for slot in new_direct_slots
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
            slots_dict[slot] = nothing
        # slot name includes reader, writer or initform
        elseif slot.head === :vect
            slot_name = slot.args[1]
            slot_options = slot.args[2:end]

            if isa(slot_name, Symbol)
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

Base.copy(m::class) = class(getfield(m, :name), copy(getfield(m, :direct_superclasses)), copy(getfield(m, :direct_slots)), copy(getfield(m, :class_precedence_list)), getfield(m, :metaclass))

@defmethod allocate_instance(classe::Class) =
    begin
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

@defmethod compute_cpl(c::Class) =
    begin
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

@defmethod initialize(classe::Class, initargs) =
begin
    for super_class in getfield(classe, :direct_superclasses)
        for super_slot in getfield(super_class, :direct_slots)
            for arg in initargs
                #println("super: ", super_slot.first)
                if arg.first == super_slot.first
                    #println("entrei")
                    getfield(super_class, :direct_slots)[super_slot.first] = arg.second
                    #println(getfield(super_class, :direct_slots))
                end
            end
        end
    end
    for (slot, value) in getfield(classe, :direct_slots)
        for arg in initargs
            if arg.first == slot
                getfield(classe, :direct_slots)[slot] = arg.second
                instance = nothing
                for (k, v) in instance_registry_2
                    if v == classe
                        instance = k
                    end
                end 
                if haskey(getfield(instance, :classtoinstance), slot)
                    #println(getfield(instance, :classtoinstance))
                    getfield(instance, :classtoinstance)[slot] = arg.second
                end
            end
        end
    end
end

function new(classe::class; kwargs...)
    instance = allocate_instance(classe)
    instance_classe = instance_registry_2[instance]
    initargs = [kwargs...]
    #println(initargs)
    #println(instance_classe)
    initialize(instance_classe, initargs)
    cpl = compute_cpl(classe)
    append!(getfield(instance_classe, :class_precedence_list), cpl)
    
    return instance
end

@defmethod compute_slots(classe::Class) =
    begin
        all_slots = Vector{Symbol}()
        append!(all_slots, keys(getfield(classe, :direct_slots)))
        cpl = compute_cpl(classe)

        for superclass in cpl
            sc_name = getfield(superclass, :name)
            if sc_name != Object && sc_name != Top && sc_name != getfield(classe, :name)
                sc_keys = keys(getfield(superclass, :direct_slots))
                for key in sc_keys
                    append!(all_slots, [key])
                end
            end
        end
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
    elseif slot == :methods
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
    #println("entrei")
    if slot == :slots
        if(classe == Class)
            return println(collect(fieldnames(class)))
        else
            return compute_slots(classe)
        end
    end

    #println("entreii")

    if slot == :direct_slots
        if isempty(keys(getfield(classe, :($slot))))
            return println([])
        else
            return println(keys(getfield(classe, :($slot))))
        end
    end
    #println("entreiii")

    if slot == :name
        return getfield(classe, :($slot))
    end

    #println("entreiiii")

    if slot == :direct_superclasses
        if isdefined(classe, slot)
            classes = []
            for c in getfield(classe, :($slot))
                push!(classes, c)
            end
            return classes
        end
    end

    #println("entreiiiii")

    if slot == :class_precedence_list
        return compute_cpl(classe)
    end

    #println("entreiiiiii")

    if (!isempty(getfield(classe, :direct_superclasses)))
        #println("entreiiiiiii")
        for superclass in getfield(classe, :direct_superclasses)
            if superclass != Object
                if (haskey(getfield(superclass, :direct_slots), slot))
                    instance = nothing
                    for (k, v) in instance_registry_2
                        if v == superclass
                            instance = k
                        end
                    end
                    #println(superclass)
                    #println(instance)
                    #return getfield(instance, :classtoinstance)[slot]
                end
            end
        end
    end

    #println("entrei1")

    for super_class in getfield(classe, :direct_superclasses)
        #println("entrei2")
        if haskey(getfield(super_class, :direct_slots), slot)
            return getfield(super_class, :direct_slots)[slot]
        end
    end

    if haskey(getfield(classe, :direct_slots), slot)
        #println("entrei3")
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
    if x == Class
        return Class
    elseif x isa instanceWrap
        classe = instance_registry_2[x]
        return class_of(classe)
    elseif x isa class
        cpl = getfield(x, :class_precedence_list)
        if !isempty(cpl)
            return cpl[1]
        elseif getfield(x, :metaclass) !== nothing
            return getfield(x, :metaclass)
        else
            return Class
        end
    elseif x isa genericFunction
        return GenericFunction
    elseif x isa multiMethod
        return MultiMethod
    elseif x isa Int64
        return _Int64
    elseif x isa Float64
        return _Float64
    elseif x isa String
        return _String
    end
end

# ------ Introspetion of classes ------

class_name(classe::class) = getfield(classe, :name)

class_slots(classe::class) =  classe.slots

class_direct_slots(classe::class) = classe.direct_slots

class_cpl(classe::class) = classe.class_precedence_list
   
class_direct_superclasses(classe::class) = classe.direct_superclasses


# ------ Function definitions for printing objects ------

#@defmethod print_object(classe::Class, io) = print(io, "<$(class_name(class_of(classe))) $(class_name(classe))>")

Base.show(io::IO, classe::class) = print_object(classe, io)
    
print_object(classe::class, io::IO) = print(io, "<$(class_name(class_of(classe))) $(class_name(classe))>")

Base.show(io::IO, instance::instanceWrap) = print_object(instance, io)

print_object(instance::instanceWrap, io::IO) = print(io,"<$(class_name(class_of(instance))) $(string(objectid(instance), base=62))>")

Base.show(io::IO, method::multiMethod) = print_object(method, io)

function print_object(method::multiMethod, io::IO)
    specializers = [class_name(spec) for spec in method_specializers(method)]
    spec_tuple = tuple(specializers...)
    if method.generic_function !== nothing
        return print(io,"<MultiMethod $(generic_name(method_generic_function(method)))$(spec_tuple)>") # its printing :bla, FIX
    else
        return print(io,"<MultiMethod>")
    end
end

Base.show(io::IO, generic::genericFunction) = print_object(generic, io)

function print_object(generic::genericFunction, io::IO)
    if generic_methods(generic) !== nothing
        return print(io,"<$(generic_name(class_of(generic))) $(generic_name(generic)) with $(length(generic_methods(generic))) methods>")
    else
        return print(io,"<$(generic_name(class_of(generic))) $(generic_name(generic)) with 0 methods>")
    end
end

# ------ Macro definition for defclass ------

macro defclass(expr...)
    readers, writers = macroproccess_class(expr[3])
    #println(readers, " and ", writers)

    quote
        global $(esc(expr[1])) = defclass($expr[1], $(expr[2].args), $(expr[3:end]))
    end
end

function macroproccess_class(expr::Expr)
    readers = Dict()
    writers = Dict()
    if length(expr.args) > 0
        if expr.args[1] isa Expr
            if expr.args[1].head == :vect
                for exp in expr.args
                    if exp.args[1] isa Symbol
                        slot_name = exp.args[1]
                    else
                        slot_name = exp.args[1].args[1]
                    end
                    if length(exp.args) == 3 || length(exp.args) == 4
                        if exp.args[2].args[1] == :reader
                            readers[slot_name] = exp.args[2].args[2]
                        end

                        if exp.args[3].args[1] == :writer
                            writers[slot_name] = exp.args[3].args[2]
                        end

                    elseif length(exp.args) == 2
                        if exp.args[2].args[1] == :reader
                            readers[slot_name] = exp.args[2].args[2]
                        elseif exp.args[2].args[1] == :writer
                            writers[slot_name] = exp.args[2].args[2]
                        end
                    end
                end
            end
        end
    end
    return readers, writers
end

# ------ Generic function call ------

(x::genericFunction)(args...) = generic_call(x, args)
(x::multiMethod)(args...) = x.procedure(args...)

function generic_call(generic::genericFunction, args)
    @assert length(args) == length(getfield(generic, :parameters))

    selected_methods = select_applicable_methods(generic, args)

    if !no_applicable_method(generic, selected_methods, args)
        return selected_methods[1].procedure(args..., call_next_method(selected_methods[2:end], args), args)
    else
        return
    end
end

function call_next_method(next_methods, args)
    for idx in 1:length(next_methods)
        next_methods[idx](args..., next_methods[idx+1:end], args)
    end
end

function select_applicable_methods(generic, args)
    argtypes = get_types_in_symbol(args)
    applicable_methods = get_applicable_methods(generic.methods, argtypes)
    sorted_methods = applicable_methods
    sort_methods(sorted_methods, argtypes)
    return sorted_methods
end

function compare_cpl(type1, type2, cpl)
    idx1 = findfirst(x -> x == type1, cpl)
    idx2 = findfirst(x -> x == type2, cpl)
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
    args1 = method_specializers(m1)
    args2 = method_specializers(m2)
    cpl_list = [getfield(arg, :class_precedence_list) for arg in argtypes]

    for (i, (arg1, arg2)) in enumerate(zip(args1, args2))
        if compare_cpl(arg1, arg2, cpl_list[i]) == true
            return true
        elseif compare_cpl(arg1, arg2, cpl_list[i]) == false
            return false
        end
    end
    return false
end

sort_methods(applicable_methods, argtypes) = sort!(applicable_methods, lt=(m1, m2) -> comparemethods(m1, m2, argtypes))

function get_applicable_methods(methods, argtypes)
    applicable_methods = []
    for method in methods
        if is_same_type(method_specializers(method), argtypes)
            push!(applicable_methods, method)
        end
    end
    return applicable_methods
end

function is_same_type(method, argtypes)
    method = method
    for i in 1:length(method)
        if !(argtypes[i] == Top)
            if !(method[i] in getfield(argtypes[i], :class_precedence_list))
                return false
            end
        end
    end
    return true
end

function get_types_in_symbol(args)
    return arg_types = map(arg -> ( if arg isa Int64 
                                        return _Int64
                                    elseif arg isa Float64
                                        return _Float64
                                    elseif arg isa String
                                        return _String
                                    elseif arg isa class
                                        return Class
                                    elseif arg isa genericFunction
                                        return GenericFunction
                                    elseif arg isa multiMethod
                                        return MultiMethod
                                    elseif arg isa instanceWrap
                                        return instance_registry_2[arg]
                                    else 
                                        return Top
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