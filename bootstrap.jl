(pwd() != @__DIR__) && cd(@__DIR__) # allow starting app from bin/ dir

ENV["GENIE_ENV"] = "prod"
ENV["PRECOMPILE"] = true
using LinkSUS
const UserApp = LinkSUS
LinkSUS.main()

LinkSUS.Genie.isrunning() || up(port=8001)

