(pwd() != @__DIR__) && cd(@__DIR__) # allow starting app from bin/ dir

using LinkSUS
# PrecompileTools.precompile("src\LinkSUS.jl")

const UserApp = LinkSUS
LinkSUS.main()
LinkSUS.Genie.isrunning() || up(8001)
