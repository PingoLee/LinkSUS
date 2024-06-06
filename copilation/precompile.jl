(pwd() != @__DIR__) && cd(@__DIR__) # allow starting app from bin/ dir

using Genie
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

const PORT = 8001


@info "Starting server"
up(PORT)


rts = LinkSUS.Genie.Router.routes()


for rt in rts
  try
    @info "Hitting route $(rt.path)"
    @time HTTP.request("GET", "http://localhost:$PORT" * rt.path)    
  catch
  end
  try
    @info "Hitting route $(rt.path)"
    @time HTTP.request("POST", "http://localhost:$PORT" * rt.path)
  catch
  end  
end


@info "Stopping server"
Genie.Server.down!()
