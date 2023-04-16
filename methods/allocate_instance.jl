include("../structures/struct_collection.jl")

@defmethod allocate_instance(classe::Class) =
    begin
        instance_classe = copy(classe)
        slots_dict = getfield(instance_classe, :direct_slots)
        instance = instanceWrap(slots_dict)
        instance_registry[instance] = instance_classe
        return instance
    end