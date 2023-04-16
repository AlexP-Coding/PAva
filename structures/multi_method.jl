struct multiMethod
    specializers::Dict{Symbol, class}
    procedure::Function
    generic_function::Union{Symbol, Nothing}
end

global MultiMethod = multiMethod(Dict(), () -> (), :GenericFunction)

# ------ Base definitions and introspection functions ------
method_generic_function(method::multiMethod) = method.generic_function

method_specializers(method::multiMethod) = reverse!(method.specializers)

Base.show(io::IO, method::multiMethod) = print_object(method, io)
