###-----------------------------------------------------------------------------
### Copyright (C) 2022- Cursor Insight
###
### All rights reserved.
###-----------------------------------------------------------------------------

module StructTools

###=============================================================================
### Exports
###=============================================================================

export @getters, @scalar

###=============================================================================
### Imports
###=============================================================================

using MacroTools: postwalk, @capture, combinedef

###=============================================================================
### Implementation
###=============================================================================

###-----------------------------------------------------------------------------
### Utilities
###-----------------------------------------------------------------------------

"""
    @scalar struct definition

Create a struct which can be broadcasted as a scalar.

```jldoctest
julia> @scalar struct A
           val::Int
       end

julia> f(a::A, x::Int) = a.val + x
f (generic function with 1 method)

julia> f.(A(2), [1, 2, 3])
3-element Vector{Int64}:
 3
 4
 5
```
"""
macro scalar(expression)
    found::Bool = false
    structtype = nothing
    expression = postwalk(expression) do node
        if !found && @capture(node, struct type_ fields__ end)
            found = true
            @capture(type, structtype{__} | structtype_)
        end

        return node
    end

    return quote
        $expression
        Base.Broadcast.broadcastable(obj::$structtype) = Ref(obj)
    end |> esc
end

###-----------------------------------------------------------------------------
### Getter generator
###-----------------------------------------------------------------------------

"""
    @getters struct definition

Create a struct whose fields have automatically generated getter functions.
Private fields without getter functions can be created with a `+` sign before
them (`+` will not be part of the name of the field).

```jldoctest
julia> @getters struct A
           val1
           +val2
       end

julia> a = A(1, 2)
A(1, 2)

julia> val1(a)
1

julia> val2(a)
ERROR: UndefVarError: val2 not defined
```
"""
macro getters(expression)
    found::Bool = false
    type = missing
    public_fields = []

    expression = postwalk(expression) do node
        if !found && @capture node struct type_ fields__ end
            found = true

            fields = map(fields) do field
                if @capture field +private_field_
                    return private_field
                else
                    push!(public_fields, field)
                    return field
                end
            end

            return :(struct $type
                         $(fields...)
                     end)
        else
            return node
        end
    end

    @assert found "Missing struct definition."

    getters::Vector{Expr} = map(public_fields) do field
        return getter(type, field)
    end

    return quote
        $expression
        $(getters...)
    end |> esc
end

function getter(type, field)::Expr
    (structtype::Symbol, parametrictypes::Vector) =
        if type isa Symbol
            type => []
        elseif @capture(type, T_{Ps__})
            T => Ps
        else
            throw(:invalid_type => type)
        end

    (fieldname::Symbol, fieldtype::Symbol) =
        if field isa Symbol
            field => :Any
        elseif @capture(field, name_::T_)
            name => T
        else
            throw(:invalid_field => field)
        end

    definition::Dict{Symbol, Any} =
        Dict(:name => fieldname,
             :args => if !isempty(parametrictypes)
                 [:(x::$structtype{$(parametrictypes...)})]
             else
                 [:(x::$structtype)]
             end,
             :kwargs => [],
             :rtype => fieldtype,
             :whereparams => parametrictypes,
             :body => :(x.$fieldname))

    return combinedef(definition)
end

end # module
