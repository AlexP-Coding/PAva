struct class
    name::Symbol
    direct_superclasses::Vector{class}
    direct_slots::Dict{Symbol, Any}
    class_precedence_list::Vector{class}
    metaclass::Union{class, Nothing}

    class(name::Symbol, direct_superclasses, direct_slots=Dict{Symbol, Any}(), class_precedence_list=[], metaclass=nothing) = new(name, direct_superclasses, direct_slots, class_precedence_list, metaclass)
end

# global dictionary to keep track of classes
class_registry = Dict{Symbol, class}()

# ------ Creation of Top, Object and BuiltInClass classes ------
global Top = class(:Top, [], Dict())
class_registry[:Top] = Top

global Object = class(:Object, [Top], Dict())
class_registry[:Object] = Object
append!(getfield(Object, :class_precedence_list), [Object, Top]) 

global BuiltInClass = class(:BuiltInClass, [Top], Dict())
class_registry[:BuiltInClass] = BuiltInClass
append!(getfield(BuiltInClass, :class_precedence_list), [BuiltInClass, Top])


global Class = class(:Class, [], Dict())
class_registry[:Class] = Class
append!(getfield(Class, :class_precedence_list), [Class, Object, Top])

# ------ Creation of special classes that represent Julia's predefined types with BuiltInClass as metaclass ------
global _Int64 = class(:_Int64, [], Dict(), [], BuiltInClass)
class_registry[:_Int64] = _Int64
append!(getfield(_Int64, :class_precedence_list), [BuiltInClass, _Int64, Top])

global _Float64 = class(:_Float64, [], Dict(), [], BuiltInClass)
class_registry[:_Float64] = _Float64
append!(getfield(_Float64, :class_precedence_list), [BuiltInClass, _Float64, Top])

global _String = class(:_String, [], Dict(), [], BuiltInClass)
class_registry[:_String] = _String
append!(getfield(_String, :class_precedence_list), [BuiltInClass, _String, Top])

global _IO = class(:_IO, [], Dict(), [], BuiltInClass)
class_registry[:_IO] = _IO
append!(getfield(_IO, :class_precedence_list), [BuiltInClass, _IO, Top])

# ------ Base definitions and introspection functions ------
Base.copy(m::class) = class(getfield(m, :name), copy(getfield(m, :direct_superclasses)), copy(getfield(m, :direct_slots)), copy(getfield(m, :class_precedence_list)), getfield(m, :metaclass))

class_name(classe::class) = getfield(classe, :name)

class_slots(classe::class) =  classe.slots

class_direct_slots(classe::class) = classe.direct_slots

class_cpl(classe::class) = classe.class_precedence_list
   
class_direct_superclasses(classe::class) = classe.direct_superclasses