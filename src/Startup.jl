module Startup

using Genie
using Stipple
using StippleUI
using StipplePlotly

using Stipple.Pages
using Stipple.ModelStorage.Sessions

include("../models/Pag_ini.jl")
using .Pag_ini

using PrecompileTools

@compile_workload begin
    init_from_storage(Importar, debounce = 30) |> Pag_ini.handlers
  
    
end

end