struct genericFunction
    name::Symbol
    parameters::Vector{Symbol}
    methods::Vector{multiMethod}

    genericFunction(name::Symbol, parameters, methods) = new(name, parameters, methods)
    
end

# global dictionary to keep track of generic functions
generic_registry = Dict{Symbol, genericFunction}()

function defgeneric(name::Symbol, parameters)
    new_generic = genericFunction(name, parameters, [])
    generic_registry[name] = new_generic
    return new_generic
end

global GenericFunction = genericFunction(:GenericFunction, [], [])
generic_registry[:GenericFunction] = GenericFunction

# ------ Base definitions and introspection functions ------
generic_name(generic::genericFunction) = getfield(generic, :name)

generic_parameters(generic::genericFunction) = generic.parameters
   
generic_methods(generic::genericFunction) = generic.methods

Base.show(io::IO, generic::genericFunction) = print_object(generic, io)
