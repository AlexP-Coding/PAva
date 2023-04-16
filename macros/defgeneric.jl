include("../structures/generic_function.jl")

macro defgeneric(expr...)
    quote
        $(esc(expr[1].args[1])) = defgeneric($expr[1].args[1], $expr[1].args[2:end])
    end
end