struct instanceWrap
    classtoinstance::Dict{Symbol, Any}
end

# ------ Base definitions and introspection functions ------
Base.getproperty(instance::instanceWrap, slot::Symbol) = Base.getproperty(instance_registry[instance], slot)

Base.show(io::IO, instance::instanceWrap) = print_object(instance, io)

print_object(instance::instanceWrap, io::IO) = print(io,"<$(class_name(class_of(instance))) $(string(objectid(instance), base=62))>")
