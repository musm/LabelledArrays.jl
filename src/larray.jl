struct LArray{T,N,Syms} <: DenseArray{T,N}
  __x::Array{T,N}
  LArray{Syms}(__x) where Syms = new{eltype(__x),ndims(__x),Syms}(__x)
  LArray{T,N,Syms}(__x) where {T,N,Syms} = new{T,N,Syms}(__x)
end

Base.size(x::LArray) = size(getfield(x,:__x))
@inline Base.getindex(x::LArray,i...) = getfield(x,:__x)[i...]
@inline Base.setindex!(x::LArray,y,i...) = getfield(x,:__x)[i...] = y

Base.propertynames(::LArray{T,N,Syms}) where {T,N,Syms} = Syms
symnames(::Type{LArray{T,N,Syms}}) where {T,N,Syms} = Syms

@inline function Base.getproperty(x::LArray,s::Symbol)
    if s == :__x
        return getfield(x,:__x)
    end
    x[s]
end

@inline function Base.setproperty!(x::LArray,s::Symbol,y)
    if s == :__x
        return setfield!(x,:__x,y)
    end
    x[s] = y
end

@inline function Base.getindex(x::LArray,s::Symbol)
  idx = findfirst(y->y==s,symnames(typeof(x)))
  getfield(x,:__x)[idx]
end

@inline function Base.setindex!(x::LArray,y,s::Symbol)
  idx = findfirst(y->y==s,symnames(typeof(x)))
  getfield(x,:__x)[idx] = y
end

function Base.similar(x::LArray{T,K,Syms},::Type{S},dims::NTuple{N,Int}) where {T,Syms,S,N,K}
    tmp = similar(x.__x,S,dims)
    LArray{S,N,Syms}(tmp)
end

# enable the usage of LAPACK
Base.unsafe_convert(::Type{Ptr{T}}, a::LArray{T,N,S}) where {T,N,S} = Base.unsafe_convert(Ptr{T}, getfield(a,:__x))

#####################################
# Broadcast
#####################################
struct LAStyle{T,N,L} <: Broadcast.AbstractArrayStyle{N} end
LAStyle{T,N,L}(x::Val{1}) where {T,N,L} = LAStyle{T,N,L}()
Base.BroadcastStyle(::Type{LArray{T,N,L}}) where {T,N,L} = LAStyle{T,N,L}()
Base.BroadcastStyle(::LabelledArrays.LAStyle{T,N,L}, ::LabelledArrays.LAStyle{E,N,L}) where{T,E,N,L} = LAStyle{promote_type(T,E),N,L}()

function Base.similar(bc::Broadcast.Broadcasted{LAStyle{T,N,L}}, ::Type{ElType}) where {T,N,L,ElType}
    return LArray{ElType,N,L}(similar(Array{ElType,N},axes(bc)))
end

"""
    @LArray Eltype Size Names
    @LArray Values Names

Creates an `LArray` with names determined from the `Names`
vector and values determined from the `Values` array. Otherwise, and eltype
and size are used to make an LArray with undefined values.

For example:

    a = @LArray Float64 (2,2) (:a,:b,:c,:d)
    b = @LArray [1,2,3] (:a,:b,:c)
"""
macro LArray(vals,syms)
  return quote
      LArray{$syms}($vals)
  end
end

macro LArray(type,size,syms)
  return quote
      LArray{$syms}(Array{$type}(undef,$size...))
  end
end

"""
    @LVector Type Names

Creates an `LArray` of dimension 1 with eltype and undefined values.
Length is via the number of names given.

For example:

    b = @LVector [1,2,3] (:a,:b,:c)
"""
macro LVector(type,syms)
  return quote
      LArray{$syms}(Vector{$type}(undef,length($syms)))
  end
end
