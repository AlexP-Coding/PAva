struct class
    name::Symbol
    direct_superclasses::Vector{class}
    direct_slots::Dict{Symbol, Any}
    class_precedence_list::Vector{class}
    metaclass::Union{class, Nothing}

    class(name::Symbol, direct_superclasses, direct_slots=Dict{Symbol, Any}(), class_precedence_list=[], metaclass=nothing) = new(name, direct_superclasses, direct_slots, class_precedence_list, metaclass)
end