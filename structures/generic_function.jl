include("multi_method.jl")

struct genericFunction
    name::Symbol
    parameters::Vector{Symbol}
    methods::Vector{multiMethod}

    genericFunction(name::Symbol, parameters, methods) = new(name, parameters, methods)
    
end

# ------ Base definitions and introspection functions ------
generic_name(generic::genericFunction) = getfield(generic, :name)

generic_parameters(generic::genericFunction) = generic.parameters
   
generic_methods(generic::genericFunction) = generic.methods