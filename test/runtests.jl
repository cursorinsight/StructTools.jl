###-----------------------------------------------------------------------------
### Copyright (C) 2022- Cursor Insight
###
### All rights reserved.
###-----------------------------------------------------------------------------

###=============================================================================
### Imports
###=============================================================================

using Test

using StructTools: @scalar, @getters
using Base: @kwdef

###=============================================================================
### Tests
###=============================================================================

@testset "Scalar" begin
    @scalar struct Unit
        n::Int
    end

    Base.:(+)(a::Unit, m::Number) = Unit(a.n + m)

    @test hasmethod(Base.Broadcast.broadcastable, Tuple{Unit})

    let unit = Unit(1)
        @test all(unit .+ (1:10) .== Unit.(2:11))
    end
end

@testset "Getters" begin
    @getters struct Square
        a
    end

    @test a isa Function
    @test length(methods(a)) == 1
    @test hasmethod(a, Tuple{Square})

    let square = Square(2)
        @test square isa Square
        @test a(square) == 2
    end

    @getters @kwdef struct Rectangle{T}
        a::T
        b::T
    end

    @test length(methods(a)) == 2
    @test hasmethod(a, Tuple{Rectangle})

    @test length(methods(b)) == 1
    @test hasmethod(b, Tuple{Rectangle})

    let rectangle = Rectangle(a = 1, b = 2)
        @test rectangle isa Rectangle{Int}
        @test a(rectangle) == 1
        @test b(rectangle) == 2
    end

    @getters @kwdef struct Triangle{T, G}
        a::T
        b::T
        +gamma::G
    end

    c(x::Triangle) = sqrt(a(x)^2 + b(x)^2 - 2 * a(x) * b(x) * cos(x.gamma))

    @test length(methods(a)) == 3
    @test hasmethod(a, Tuple{Triangle})
    @test length(methods(b)) == 2
    @test hasmethod(b, Tuple{Triangle})
    @test_throws UndefVarError gamma

    let triangle = Triangle(a = 1, b = 1, gamma = pi/2)
        @test triangle isa Triangle{Int, Float64}
        @test a(triangle) == 1
        @test b(triangle) == 1
        @test c(triangle) ≈ sqrt(2)
    end
end
