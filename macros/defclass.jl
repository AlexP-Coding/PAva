macro defclass(expr...)
    readers, writers = macroproccess_class(expr[3])
    println(readers, " and ", writers)

    quote
        global $(esc(expr[1])) = defclass($expr[1], $(expr[2].args), $(expr[3:end]))
    end
end

function defclass(name::Symbol, direct_superclasses, direct_slots; kwargs...)
    slots_dict = Dict()
    if length(direct_slots) == 2
        metaclass = direct_slots[2]
        new_direct_slots = direct_slots[1].args
    elseif length(direct_slots) == 1
        new_direct_slots = direct_slots[1].args
    elseif length(direct_slots) == 0
        new_direct_slots = direct_slots
    end

    for slot in new_direct_slots
        for superclass in direct_superclasses
            superclassClass = class_registry[superclass]
            for super_slot in getfield(superclassClass, :direct_slots)
                if slot == super_slot.first
                    error("Duplicated slots!")
                end
            end
        end
        if isa(slot, Symbol)
            slots_dict[slot] = nothing
        elseif slot.head === :vect
            slot_name = slot.args[1]
            slot_options = slot.args[2:end]

            if isa(slot_name, Symbol)
                slots_dict[slot_name] = nothing
            else
                slots_dict[slot_name.args[1]] = slot_name.args[2]
            end
            
            for option in slot_options
                transformed_option = Pair(option.args[1], option.args[2])
                if :initform in transformed_option
                    slots_dict[slot_name] = transformed_option.second
                end
            end

        elseif isa(slot.head, Symbol)
            transformed_slot = Pair(slot.args[1], slot.args[2])
            slots_dict[transformed_slot.first] = transformed_slot.second
        end
    end
    
    new_superclasses = Vector{class}()
    
    for classe in direct_superclasses
        class_obj = class_registry[classe]
        push!(new_superclasses, class_obj)
    end

    if !(Object in direct_superclasses)
        class_objet = class_registry[:Object]
        push!(new_superclasses, class_objet)
    end

    if length(direct_slots) == 2
        class_objet = class_registry[metaclass.args[2]]
        new_classe = class(name, new_superclasses, slots_dict, [], class_objet)
    else
        new_classe = class(name, new_superclasses, slots_dict, [])
    end
    class_registry[name] = new_classe
    return new_classe
end