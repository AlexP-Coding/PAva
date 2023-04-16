struct multiMethod
    specializers::Dict{Symbol, Any}
    procedure::Function
    generic_function::Symbol
end

# global dictionary to keep track of methods 
method_registry = Dict{Symbol, multiMethod}() 

global MultiMethod = multiMethod(Dict(), () -> (), :GenericFunction)
method_registry[:MultiMethod] = MultiMethod 

# ------ Base definitions and introspection functions ------
method_generic_function(method::multiMethod) = method.generic_function

method_specializers(method::multiMethod) = reverse!(method.specializers)