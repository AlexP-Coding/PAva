include("../structures/struct_collection.jl")

@defmethod compute_slots(classe::Class) =
    begin
        all_slots = Vector{Symbol}()
        append!(all_slots, keys(getfield(classe, :direct_slots)))
        cpl = compute_cpl(classe)
        for superclass in cpl
            sc_name = getfield(superclass, :name)
            if sc_name != Object && sc_name != Top && sc_name != getfield(classe, :name)
                sc_keys = keys(getfield(superclass, :direct_slots))
                for key in sc_keys
                    append!(all_slots, [key])
                end
            end
        end
        return all_slots
    end