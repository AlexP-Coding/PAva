include("../structures/generic_function.jl")

macro defgeneric(expr...)
    quote
        $(esc(expr[1].args[1])) = defgeneric($expr[1].args[1], $expr[1].args[2:end])
    end
end

function defgeneric(name::Symbol, parameters)
    if !(haskey(generic_registry, name))
        new_generic = genericFunction(name, parameters, [])
        generic_registry[name] = new_generic
    else
        new_generic = generic_registry[name]
    end
    return new_generic
end

# global dictionary to keep track of generic functions
generic_registry = Dict{Symbol, genericFunction}()

global GenericFunction = genericFunction(:GenericFunction, [], []) 
generic_registry[:GenericFunction] = GenericFunction 