using Genie
using Stipple
using StippleUI
using StipplePlotly

using Stipple.Pages
using Stipple.ModelStorage.Sessions

using LinkSUS.Pag_ini

if Genie.Configuration.isprod()
  Genie.Assets.assets_config!([Genie, Stipple, StippleUI, StipplePlotly], host = "https://cdn.statically.io/gh/GenieFramework")
end

# paginas de cruzamento
Page("/", view = "views/hello.jl.html",
          layout = "layouts/app.jl.html",
          model = () -> init_from_storage(Importar, debounce = 30) |> Pag_ini.handlers,
          context = @__MODULE__)

route("/sub", method = POST) do  
  return Pag_ini.receb_arquivos()
end

route("/cruzar", method = GET) do  
  return Pag_ini.blocagem()
end
