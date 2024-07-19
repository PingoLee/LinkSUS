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


include(abspath("src/importadores.jl"))
ENV["PRECOMPILE"] == "false" && LinkSUS.Genie.Revise.track(LinkSUS, "src/importadores.jl")
using .importadores
include(abspath("src/linkage_f.jl"))
ENV["PRECOMPILE"] == "false" && LinkSUS.Genie.Revise.track(LinkSUS, "src/linkage_f.jl")
using .linkage_f
include(abspath("src/relatorio.jl"))
ENV["PRECOMPILE"] == "false" && LinkSUS.Genie.Revise.track(LinkSUS, "src/relatorio.jl")
using .relatorio
include(abspath("src/Pag_ini.jl"))
ENV["PRECOMPILE"] == "false" && LinkSUS.Genie.Revise.track(LinkSUS, "src/Pag_ini.jl")
using .Pag_ini
include(abspath("src/Pag_config.jl"))
ENV["PRECOMPILE"] == "false" && LinkSUS.Genie.Revise.track(LinkSUS, "src/Pag_config.jl")
using .Pag_config
include(abspath("src/Pag_config_rel.jl"))
ENV["PRECOMPILE"] == "false" && LinkSUS.Genie.Revise.track(LinkSUS, "src/Pag_config_rel.jl")
using .Pag_config_rel

# if ENV["PRECOMPILE"] == "false"  
#   LinkSUS.Genie.Revise.track("src/importadores.jl")
#   LinkSUS.Genie.Revise.track("src/linkage_f.jl")
#   LinkSUS.Genie.Revise.track("src/relatorio.jl")
#   LinkSUS.Genie.Revise.track("src/Pag_ini.jl")
#   LinkSUS.Genie.Revise.track("src/Pag_config.jl")
#   LinkSUS.Genie.Revise.track("src/Pag_config_rel.jl")
# end

