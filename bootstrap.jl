println(pwd())
println(@__DIR__)
(pwd() != @__DIR__) && cd(@__DIR__) # allow starting app from bin/ dir

using LinkSUS
# PrecompileTools.precompile("src\LinkSUS.jl")

const UserApp = LinkSUS
LinkSUS.main()
LinkSUS.Genie.isrunning() || up(port=8001)
# run(`start "C:\Program Files\Google\Chrome\Application\chrome.exe" "http://localhost:8001/"`)
