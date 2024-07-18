# Pkg.develop(PackageSpec(path="c:/Sistemas/Genie.jl"))
ENV["PRECOMPILE"] = false
ENV["GENIE_ENV"] = "dev"

# ENV["PRECOMPILE"] = true
# ENV["GENIE_ENV"] = "prod"

# using Genie

using Pkg
Pkg.activate(".")

using LinkSUS

LinkSUS.main()

LinkSUS.Genie.isrunning() || up(port=8001)

@time println("foi")

@time LinkSUS.Genie.Renderer.Html.html(LinkSUS.Genie.Renderer.filepath("layouts\\templates\\linkage.jl.html"), layout = LinkSUS.Genie.Renderer.filepath("layouts\\app.jl.html"), scripts="<script src='/js/cust/linksus.js'></script>")

# a = LinkSUS.Genie.Renderer.Html.html(LinkSUS.Genie.Renderer.filepath("layouts\\templates\\linkage.jl.html"), layout = LinkSUS.Genie.Renderer.filepath("layouts\\app.jl.html"), scripts="<script src='/js/cust/linksus.js'></script>")

# layout = LinkSUS.Genie.Renderer.filepath("layouts\\app.jl.html")

# slayout = read(layout, String)

# view = LinkSUS.Genie.Renderer.filepath("layouts\\templates\\linkage.jl.html")
# sview = read(view, String)

@time LinkSUS.Genie.Renderer.Html.raw_html(LinkSUS.Genie.Renderer.filepath("layouts\\templates\\linkage.jl.html"), layout = LinkSUS.Genie.Renderer.filepath("layouts\\app.jl.html"), scripts="<script src='/js/cust/linksus.js'></script>")

using HTTP

@time HTTP.request("GET", "http://127.0.0.1:8001/") 