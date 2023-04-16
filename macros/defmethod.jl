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