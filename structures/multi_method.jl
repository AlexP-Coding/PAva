struct multiMethod
    specializers::Dict{Symbol, class}
    procedure::Function
    generic_function::Union{Symbol, Nothing}
end