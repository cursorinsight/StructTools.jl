# StructTools.jl

[![CI](https://github.com/cursorinsight/StructTools.jl/actions/workflows/CI.yml/badge.svg)](https://github.com/cursorinsight/StructTools.jl/actions/workflows/CI.yml)

StructTools.jl is a Julia package that provides variopus utilities for structs.

## Installation

```julia
julia>]
pkg> add https://github.com/cursorinsight/StructTools.jl
```

## Usage

Load the package via

```julia
using StructTools
```

### Getter generator

With `@getters` macro you can create a struct whose fields have automatically
generated getter functions.

Private fields without getter functions can also be created with a `+` sign
before them (`+` will not be part of the name of the field).

```julia
@getters struct A
    val1
    +val2
end

a = A(1, 2)

val1(a) # 1
val2(a) # throws UndefVarError

fields = fieldnames(A)  # (:val1, :val2)
```

### Scalar fields

With `@scalar` macro you can create a struct which can be broadcasted as a
scalar.

```julia
# WITH @scalar
@scalar struct B
    val::Int
end

add(b::B, x::Int) = b.val + x

res = add.(B(2), [1, 2, 3]) # [3, 4, 5]

# WITHOUT @scalar
struct C
    val::Int
end

add(c::C, x::Int) = c.val + x

res = add.(C(2), [1, 2, 3]) # throws MethodError
```
