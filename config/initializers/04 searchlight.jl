using SearchLight
using SearchLightSQLite

function LinkSUS.Genie.Renderer.Json.JSON3.StructTypes.StructType(::Type{T}) where {T<:SearchLight.AbstractModel}
  LinkSUS.Genie.Renderer.Json.JSON3.StructTypes.Struct()
end

function Genie.Renderer.Json.JSON3.StructTypes.StructType(::Type{SearchLight.DbId})
  LinkSUS.Genie.Renderer.Json.JSON3.StructTypes.Struct()
end

SearchLight.Configuration.load(context = @__MODULE__)
SearchLight.connect()


