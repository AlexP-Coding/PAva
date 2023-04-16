macro defclass(expr...)
    readers, writers = macroproccess_class(expr[3])
    println(readers, " and ", writers)

    quote
        global $(esc(expr[1])) = defclass($expr[1], $(expr[2].args), $(expr[3:end]))
    end
end

function defclass(name::Symbol, direct_superclasses, direct_slots; kwargs...)
    #slots_dict = Dict(slot => nothing for slot in direct_slots)
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
        # only slot name is provided
        if isa(slot, Symbol)
            slots_dict[slot] = nothing
        # slot name includes reader, writer or initform
        elseif slot.head === :vect
            slot_name = slot.args[1]
            slot_options = slot.args[2:end]

            if isa(slot_name, Symbol)
                #slots_dict[slot] = direct_slots[slot]
                slots_dict[slot_name] = nothing
            else
                #println("Vector with Name and Value")
                slots_dict[slot_name.args[1]] = slot_name.args[2]
            end
            
            for option in slot_options
                transformed_option = Pair(option.args[1], option.args[2])
                #if haskey(slot_options, :initform)
                if :initform in transformed_option
                    #println("Vector slot name as initform")
                    #slots_dict[slot_name] = slot_options[:initform]
                    slots_dict[slot_name] = transformed_option.second
                #if haskey(slot_options, :reader)

                # isso acho que passa para a macro
                elseif :reader in transformed_option
                    println("Stored a reader method")
                    #=@defgeneric get_name(o)
                    @defgeneric get_age(o)
                    @defgeneric get_friend(o)=#

                elseif :writer in transformed_option
                    println("Stored a writer method")
                    #=@defgeneric set_name!(o)
                    @defgeneric set_age!(o)
                    @defgeneric set_friend!(o)=#
                end
            end

        # slot name with iniform value are provided
        elseif isa(slot.head, Symbol)
            #println("Name and Value")
            #slots_dict[slot] = direct_slots[slot]
            #doing it like a pair
            transformed_slot = Pair(slot.args[1], slot.args[2])
            slots_dict[transformed_slot.first] = transformed_slot.second
        end
    end
    
    
    #slots_dict = Dict(direct_slots[1] => nothing for slot in direct_slots)
    
    new_superclasses = Vector{class}()
    
    # all classes inherit, directly or indirectly from Object class
    for classe in direct_superclasses
        class_obj = class_registry[classe]
        push!(new_superclasses, class_obj)
    end

    if !(Object in direct_superclasses)
        class_objet = class_registry[:Object]
        push!(new_superclasses, class_objet)
    end

    if length(direct_slots) == 2
        # a metaclass was received
        # name becames the metaclass name??
        class_objet = class_registry[metaclass.args[2]]
        new_classe = class(name, new_superclasses, slots_dict, [], class_objet)
    else
        new_classe = class(name, new_superclasses, slots_dict, [])
    end
    #println("estou aqui")
    class_registry[name] = new_classe
    return new_classe
end