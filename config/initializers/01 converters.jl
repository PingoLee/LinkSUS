using Dates
import Base.convert

convert(::Type{Int}, v::SubString{String}) = parse(Int, v)
convert(::Type{Float64}, v::SubString{String}) = parse(Float64, v)
convert(::Type{Date}, s::String) = parse(Date, s)
convert(::Type{DateTime}, s::String) = parse(DateTime, s)

function get_values(dict::Dict{Symbol, Any}, key::Symbol; return_value::Union{DataType, Nothing} = nothing)
  if haskey(dict, key)
    return return_value |> isnothing ? dict[key] : parse(return_value, dict[key])
  else
    return missing
  end
end
function get_values(dict::Dict{Symbol, Any}, key::AbstractString; return_value::Union{DataType, Nothing} = nothing)
  key = Symbol(key)
  return get_values(dict, key, return_value=return_value)  
end

function check_values(dict::Dict{Symbol, Any}, key::Symbol)
  # check if key exists in dict, and if exists, if it is not "", [], or missing
  if haskey(dict, key) && dict[key] |> !ismissing  && dict[key] != "" && dict[key] != [] 
    return true
  else
    return false
  end
end
function check_values(dict::Dict{Symbol, Any}, key::AbstractString)
  key = Symbol(key)
  return check_values(dict, key)  
end


@kwdef mutable struct Payload
  dict::Dict{Symbol, Any}
  get::Function = (x::Union{Symbol, AbstractString}) -> get_values(dict, x) 
  get_number::Function = (x::Union{Symbol, AbstractString}) -> get_values(dict, x, return_value = Int64)
  check::Function = (x::Union{Symbol, AbstractString}) -> check_values(dict, x)   
end

function dictpl(dict::Dict{Symbol, Any})
  return Payload(dict = dict)
end
