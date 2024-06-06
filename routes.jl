using Genie
using Stipple
using StippleUI
using StipplePlotly

using Stipple.Pages
using Stipple.ModelStorage.Sessions

using LinkSUS.Pag_ini
using LinkSUS.Pag_config
using LinkSUS.Pag_config_rel

import Genie.Renderer.Html: normal_element, register_normal_element
register_normal_element("q__td", context = @__MODULE__)


if Genie.Configuration.isprod()
  Genie.Assets.assets_config!([Genie, Stipple, StippleUI, StipplePlotly], host = "https://cdn.statically.io/gh/GenieFramework")
end

# paginas de cruzamento
Page("/", view = "views/linkage.jl.html",
          layout = "layouts/app.jl.html",
          model = () -> init_from_storage(Importar, debounce = 30) |> Pag_ini.handlers,
          context = @__MODULE__)

route("/sub", method = POST) do  
  return Pag_ini.receb_arquivos()
end

route("/cruzar", method = GET) do  
  return Pag_ini.linkage_det()
end

route("/rel_nsus_covid_pos", method = POST) do  
  return Pag_ini.processa_notificasus()
end

# CONFIGURAÇÃO
Page("/config", view = "views/config.jl.html",
  layout = "layouts/app.jl.html",
  model = () -> init_from_storage(Config, debounce = 30) |> Pag_config.handlers,
  context = @__MODULE__)

Page("/config_rel", view = "views/config_rel.jl.html",
  layout = "layouts/app.jl.html",
  model = () -> init_from_storage(Config_rel, debounce = 30) |> Pag_config_rel.handlers,
  context = @__MODULE__)

route("/api/logout", method = GET) do  
  exit()
end


