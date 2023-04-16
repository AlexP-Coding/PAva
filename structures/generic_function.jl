struct genericFunction
    name::Symbol
    parameters::Vector{Symbol}
    methods::Vector{multiMethod}

    genericFunction(name::Symbol, parameters, methods) = new(name, parameters, methods)
    
end