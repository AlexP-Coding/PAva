# Group 3
# Alexandra Rodrigues 95528
# Alexandra Pato 97375
# Miguel Encarnacao 105718
# Mafalda Cravo 105728

include("structures/struct_collection.jl")
include("macros/macro_collection.jl")

# global dictionary to keep track of classes of instances
instance_registry = Dict{instanceWrap, class}()

# ------ Function definitions ------

@defmethod allocate_instance(classe::Class) =
    begin
        instance_classe = copy(classe)
        slots_dict = getfield(instance_classe, :direct_slots)
        instance = instanceWrap(slots_dict)
        instance_registry[instance] = instance_classe
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

function initialize(instance::instanceWrap; kwargs...)
    classe = instance_registry[instance]
    for super_class in getfield(classe, :direct_superclasses)
        for super_slot in getfield(super_class, :direct_slots)
            if haskey(kwargs, super_slot.first)
                getfield(super_class, :direct_slots)[super_slot.first] = kwargs[super_slot.first]
            end
        end
    end
    for (slot, _) in getfield(classe, :direct_slots)
        if haskey(kwargs, slot)
            getfield(classe, :direct_slots)[slot] = kwargs[slot]
            if haskey(getfield(instance, :classtoinstance), slot)
                getfield(instance, :classtoinstance)[slot] = kwargs[slot]
            end
        end
    end
end

function new(classe::class; kwargs...)
    instance = allocate_instance(classe)
    instance_classe = instance_registry[instance]
    initialize(instance; kwargs...)
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
            return generic_registry[getfield(method, :($slot))]
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
        return compute_cpl(classe)
    end

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
    classe = instance_registry[instance]
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
        classe = instance_registry[x]
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

#@defmethod print_object(classe::Class, io) = print(io, "<$(class_name(class_of(classe))) $(class_name(classe))>")

function print_object(method::multiMethod, io::IO)
    specializers = [class_name(spec) for spec in method_specializers(method)]
    spec_tuple = tuple(specializers...)
    if method.generic_function !== nothing
        return print(io,"<MultiMethod $(generic_name(method_generic_function(method)))$(spec_tuple)>") # its printing :bla, FIX
    else
        return print(io,"<MultiMethod>")
    end
end

function print_object(generic::genericFunction, io::IO)
    if generic_methods(generic) !== nothing
        return print(io,"<$(generic_name(class_of(generic))) $(generic_name(generic)) with $(length(generic_methods(generic))) methods>")
    else
        return print(io,"<$(generic_name(class_of(generic))) $(generic_name(generic)) with 0 methods>")
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
        if !(method[i] in getfield(argtypes[i], :class_precedence_list))
            return false
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
                                    else 
                                        return instance_registry[arg]
                                    end), args)
end

function no_applicable_method(generic, selected_methods, args)
    if length(selected_methods) > 0
        return false
    else
        println("ERROR: No applicable method for function $(generic_name(generic)) with arguments $(args)")
        return true
    end
end