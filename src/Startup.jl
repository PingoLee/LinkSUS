module Startup

using LinkSUS
using PrecompileTools

println("Server compile")

# set_preferences!(LinkSUS, "precompile_workload" => false; force=false)

using PrecompileTools: @setup_workload, @compile_workload, verbose
# LinkSUS.HTTP.request("GET", "http://127.0.0.1:8001/session") |> println

verbose[] = true

@setup_workload begin
 
  @compile_workload begin
    LinkSUS.HTTP.request("GET", "http://127.0.0.1:8001/session") 
    LinkSUS.HTTP.request("GET", "http://127.0.0.1:8001/") 
    LinkSUS.Pag_ini.cruzamento(1) |> LinkSUS.Genie.Renderer.Json.json 

  end
end

println("Server compile done")


end