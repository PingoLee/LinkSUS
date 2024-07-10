# Optional flat/non-resource MVC folder structure
# Genie.Loader.autoload(abspath("models"))
# LinkSUS.Loader.autoload(
#   abspath("src", "importadores.jl"), 
#   abspath("src", "linkage_f.jl"), 
#   abspath("src", "relatorio.jl"), 
#   abspath("src", "Pag_ini.jl"),
#   abspath("src", "Pag_config.jl"),
#   abspath("src", "Pag_config_rel.jl")
# )

println(abspath("src/importadores.jl"))

include(abspath("src/importadores.jl"))
using .importadores
include(abspath("src/linkage_f.jl"))
using .linkage_f
include(abspath("src/relatorio.jl"))
using .relatorio
include(abspath("src/Pag_ini.jl"))
using .Pag_ini
include(abspath("src/Pag_config.jl"))
using .Pag_config
include(abspath("src/Pag_config_rel.jl"))
using .Pag_config_rel


println("concluido autoload.jl")