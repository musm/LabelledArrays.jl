using LabelledArrays
using Test

ABC = @SLVector (:a,:b,:c)
b = ABC(1,2,3)

@test b.a == 1
@test b.b == 2
@test b.c == 3
@test b[1] == b.a
@test b[2] == b.b
@test b[3] == b.c

@test_throws UndefVarError fill!(a,1)
@test typeof(b.__x) == SVector{3,Int}

# Type stability tests
ABC_fl = @SLVector Float64 (:a, :b, :c)
ABC_int = @SLVector Int (:a, :b, :c)
@test similar_type(b, Float64) == ABC_fl
@test typeof(copy(b)) == ABC_int
@test typeof(Float64.(b)) == ABC_fl
@test typeof(b .+ b) == ABC_int
@test typeof(b .+ 1.0) == ABC_fl
@test typeof(zero(b)) == ABC_int
@test similar(b) isa MArray # similar should return a mutable copy
