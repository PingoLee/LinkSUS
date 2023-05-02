(pwd() != @__DIR__) && cd(@__DIR__) # allow starting app from bin/ dir

using LinkSUS
const UserApp = LinkSUS
LinkSUS.main()
up()
