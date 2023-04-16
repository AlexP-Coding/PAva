struct instanceWrap
    classtoinstance::Dict{Symbol, Any}
end

# ------ Base definitions and introspection functions ------
Base.getproperty(instance::instanceWrap, slot::Symbol) = Base.getproperty(instance_registry[instance], slot)