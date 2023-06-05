(pwd() != @__DIR__) && cd(@__DIR__) # allow starting app from bin/ dir

using LinkSUS
# PrecompileTools.precompile("src\LinkSUS.jl")

const UserApp = LinkSUS
LinkSUS.main()

include("packages.jl")
using PrecompileSignatures

for p in PACKAGES
  @show "Precompiling signatures for $p"
  Core.eval(@__MODULE__, Meta.parse("import $p"))
  Core.eval(@__MODULE__, Meta.parse("@precompile_signatures($p)"))
end

import LinkSUS.Genie.Requests.HTTP

@info "Hitting routes"

for r in LinkSUS.Genie.Router.routes()
  try
    r.action()
  catch
  end
end

@info "Iniciando funções"

const PORT = 8000

try
  @info "Starting server"
  up(PORT)
catch
end

rts = LinkSUS.Genie.Router.routes()

try
  #TODO: Ask adrian if I should filter /geniepackagemanager/* /stippleui/* /_devtools_/* tobe hit by HTTP
  for rt in rts
    @time HTTP.request("GET", "http://localhost:$PORT" * rt.path)
  end
catch
end

try
  @info "Stopping server"
  Genie.Server.down!()
catch
end