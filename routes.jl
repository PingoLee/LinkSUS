using Genie.Router

using Genie.Requests
using Genie, GenieSession, GenieSessionFileSession, Genie.Renderer.Json

import LinkSUS: Pag_ini, dictpl, Pag_config, Pag_config_rel
# using LinkSUS.Pag_config_rel
using HTTP

route("/session") do
  s = session(params())
  if !haskey(s.data, :number)
      GenieSession.set!(s, :number, rand())
  end
  s.data |> json
end


route("/") do
  Genie.Renderer.Html.raw_html(Genie.Renderer.filepath("layouts\\templates\\linkage.jl.html"), layout = Genie.Renderer.filepath("layouts\\app.jl.html"), scripts="<script src='/js/cust/linksus.js'></script>")
end

route("/get_number") do
  s = session(params())
  if !haskey(s.data, :number)
      return Genie.Renderer.redirect(:get) # index / is associated with symbol :get
  end
  "Your random number is $(s.data[:number])
  <br> <a href='/clear_data'>Clear data</a>"

end

route("/clear_data") do
  s = session(params())
  s.data = Dict()
  "Data cleared!
  <br> <a href='/get_number'>Get number</a>"
end


route("/sub", method = POST) do  
  return Pag_ini.receb_arquivos()
end

route("/cruzar", method = GET) do  
  return Pag_ini.linkage_det()
end

route("/rel_nsus_covid_pos", method = POST) do  
  return Pag_ini.processa_notificasus()
end

# route("/get_cruzamentos") do 
#   println(Pag_ini.cruzamentos())
#   Pag_ini.cruzamentos() |> json
# end

route("/get_load") do
  Pag_ini.get_load() |> json
end

route("/get_bd") do
  println(getpayload())
  Pag_ini.cruzamento(getpayload()[:cruzamento]) |> json    
end

route("/change_rev") do
  println(getpayload())
  return Pag_ini.change_rev(parse(Int64, getpayload()[:row_rev]), parse(Int64, getpayload()[:max_rev])) |> json
end

route("/onreset") do
  return Pag_ini.onreset(getpayload()[:cruzamento] |> x -> parse(Int64, x)) |> json
end

route("/revisa_row_par") do
  request = getpayload()
  println(request)
  row::Int64 = parse(Int64, request[:row])
  par::String = request[:par]
  return Pag_ini.revisa_row_par(row, par) |> json
end

route("/conclui_rev_bt") do 
  Pag_ini.conclui_rev_bt(getpayload()[:crz_id]) |> json
end

route("/rel_bt_pad") do 
  Pag_ini.rel_bt_pad(getpayload() |> dictpl) |> json  
end

route("/get_rel_avan") do 
  Pag_ini.get_rel_avan(getpayload() |> dictpl) |> json  
end

route("/rel_bt_avan") do 
  Pag_ini.rel_bt_avan(getpayload() |> dictpl) |> json  
end


# CONFIGURAÇÃO
route("/config") do
  Genie.Renderer.Html.raw_html(Genie.Renderer.filepath("layouts\\templates\\config.jl.html"), layout = Genie.Renderer.filepath("layouts\\app.jl.html"), scripts="<script setup src='/js/cust/config.js'></script>")
end

route("/config_back") do 
  # println(getpayload())
  request = getpayload() |> dictpl
  resposta = request.get("resposta")
  println(request)
  other = request.get("other")

  if resposta == "get_bds"
    println("foi")
    return Pag_config.get_bds() |> json
  elseif resposta == "watch_bdsel"
    return Pag_config.watch_bdsel(request) |> json
  elseif resposta == "edit_bt"
    return Pag_config.edit_bt(request) |> json
  elseif resposta == "replc_edit_bt"
    return Pag_config.replc_edit_bt(request) |> json
  elseif resposta == "mult_bt"
    return Pag_config.mult_bt(request) |> json
  elseif resposta == "del_bt"
    return Pag_config.del_bt(request) |> json
  elseif resposta == "obrig_bt"
    return Pag_config.obrig_bt(request) |> json
  elseif resposta == "replc_del_bt"
    return Pag_config.replc_del_bt(request) |> json
  elseif resposta == "prep_edit_bt"
    return Pag_config.prep_edit_bt(request) |> json
  elseif resposta == "prep_del_bt"
    return Pag_config.prep_del_bt(request) |> json
  end
end

# CONFIGURAÇÃO rel
route("/config_rel") do
  Genie.Renderer.Html.html(Genie.Renderer.filepath("layouts\\templates\\config_rel.jl.html"), layout = Genie.Renderer.filepath("layouts\\app.jl.html"), scripts="<script setup src='/js/cust/config_rel.js'></script>")
end

route("/config_rel_back") do 
  # println(getpayload())
  request = getpayload() |> dictpl
  resposta = request.get("resposta")
  println(request)

  if resposta == "get_crz"
    return Pag_config_rel.get_crz() |> json
  elseif resposta == "selcrz"
    return Pag_config_rel.selcrz(request) |> json
  elseif resposta == "selrel"
    return Pag_config_rel.selrel(request) |> json
  elseif resposta == "col_bt"
    return Pag_config_rel.col_bt(request) |> json
  elseif resposta == "save_row_bt"
    return Pag_config_rel.save_row_bt(request) |> json
  elseif resposta == "del_cz_bt"
    return Pag_config_rel.del_cz_bt(request) |> json
  elseif resposta == "down_row_bt"
    return Pag_config_rel.down_row_bt(request) |> json
  elseif resposta == "up_row_bt"
    return Pag_config_rel.up_row_bt(request) |> json
  end
end






