(pwd() != @__DIR__) && cd(@__DIR__) # allow starting app from bin/ dir

using PrecompileTools
using Genie
using LinkSUS

# PrecompileTools.precompile("src\LinkSUS.jl")
const UserApp = LinkSUS
LinkSUS.main()


import LinkSUS.Genie.Requests.HTTP

@info "Hitting routes"

for r in LinkSUS.Genie.Router.routes()
  try
    r.action()
  catch
  end
end