module Pag_config

using Unicode
using Genie.Renderer.Json
using DataFrames, CSV


import LinkSUS.SearchLight: query, connection
import LinkSUS: Payload


function update_ordem_col(df::DataFrame)
  ordem = 1
  for item in eachrow(df)   
    item.ordem != ordem && (query("update banco_cols set ordem=$ordem where id=$(item.id)"); item.ordem = ordem)
    ordem += 1
  end    
end

function get_cols(loc)
  local df = query("select * from banco_cols where banco_id=$loc order by ordem, id asc")
  update_ordem_col(df)
  df.obrig = map(x -> x == 1, df.obrig)  
  local c = [] 
  for item in eachrow(df)   
      push!(c, Dict(pairs(NamedTuple(item))))  
  end  
  return c
end

function get_replc(loc)
  local df = query("select * from banco_subs where banco_id=$loc")  
  local c = [] 
  for item in eachrow(df)   
      push!(c, Dict(pairs(NamedTuple(item))))  
  end  
  return c
end

function get_prep(loc)
  local df = query("select * from banco_prep where banco_id=$loc")  
  local c = [] 
  for item in eachrow(df)   
      push!(c, Dict(pairs(NamedTuple(item))))  
  end  
  return c
end


function get_bds()
  local df1 = query("select * from bancos")
  local c = [] 
  for bd in eachrow(df1)   
      push!(c, Dict(pairs(NamedTuple(bd))))  
  end  
  return c
end

function bdobs_bt(request::Payload)     
  sql = """UPDATE bancos
              SET 
              obs = '$(request.get("bdobs"))'
              WHERE id = $(request.get_number("bdsel"));"""

  query(sql)
end 

function watch_bdsel(request::Payload)
  resp = Dict()
  resp["col_imp"] = get_cols(request.get_number(:bdsel))
  resp["col_replc"] = get_replc(request.get_number(:bdsel))
  resp["col_prep"] = get_prep(request.get_number(:bdsel))

  sql = """select obs from bancos                
              WHERE id = $(request.get_number(:bdsel));"""

  df = query(sql)
  

  ismissing(df[1, :obs]) ? resp["bdobs"] = "" : resp["bdobs"] = (df[1, :obs])

  return resp
  
end 

function edit_bt(request::Payload) 
  isnothing(request.get("function")) ? func = "null" : func = "'$(request.get("function"))'"
  
  if request.get_number("id_row") != 0
    sql = """update banco_cols set
            col = '$(request.get("col")))',
            function = $(func),
            obrig = $(request.get("obrig"))
          WHERE id = $(request.get_number("id_row")) and banco_id = $(request.get_number("bdsel"));"""    
  else
    sql = """
        INSERT INTO banco_cols 
        (col,function,obrig,ordem,banco_id)
        values
        ('$(request.get("col"))', $(func),$(request.get("obrig")),$(request.get("ordem")),$(request.get_number("bdsel")))"""
  end
  query(sql)

  return Dict("col_imp" => get_cols(request.get_number("bdsel")))
  
end

function del_bt(request)    
    resp = Dict()

    sql = """
      DELETE FROM banco_cols 
      WHERE id = $(request.get_number("id_row")) and banco_id = $(request.get_number("bdsel"));"""

    query(sql)

    resp["col_imp"] = get_cols(request.get_number("bdsel"))
    return resp
        
  end

  function mult_bt(request::Payload)
    #println(model.mult_data[])
    resp = Dict()
    bdsel = request.get_number("bdsel")
    mult_data = request.get("mult_data")
    vars = split(mult_data, ",")
    vals = [] 
    ordem = size(model.col_imp[], 1)
    dfo = query("select count(ordem) as count from banco_cols where banco_id=$(bdsel)")
    if size(dfo, 1) == 0
      resp["error"] = "Erro ao buscar ordem"
      return resp
    else
      ordem = dfo[1, :count]
    end

    for item in vars
      ordem += 1
      push!(vals, "($ordem, '$item', null, true, $(bdsel))")
    end  
    sql = """
          INSERT INTO banco_cols 
          (ordem,col,function,obrig,banco_id)
          values
          $(join(vals, ","))"""

    #println(sql)
    query(sql)

    resp["col_imp"] = get_cols(bdsel)
    return resp
  end

function obrig_bt(request::Payload)
  # sql = """update banco_cols set           
  #         obrig = $(model.edit_row[]["obrig"])
  #       WHERE id = $(model.edit_row[]["id"]) and banco_id = $(model.bdsel[]);"""    
  
  # query(sql)    
  resp = Dict()
  obrig = request.get("obrig")
  println(obrig)
  
  obrig == "true" ? obrig = 1 : obrig = 0
  sql = """update banco_cols set           
          obrig = $obrig
        WHERE id = $(request.get_number("id_row")) and banco_id = $(request.get_number("bdsel"));"""
  
  query(sql)
end


function replc_edit_bt(request::Payload)
    
  if request.get_number("id_row") != 0
    sql = """update banco_subs set
            antigo = '$(request.get("antigo"))',              
            novo = '$(request.get("novo"))'
          WHERE id = $(request.get_number("id_row")) and banco_id = $(request.get_number("bdsel"));"""    
  else
    sql = """
        INSERT INTO banco_subs 
        (antigo,novo,banco_id)
        values
        ('$(request.get("antigo"))', '$(request.get("novo"))', $(request.get_number("bdsel")))"""
  end

  query(sql)

  return Dict("col_replc" => get_replc(request.get_number("bdsel")))
  
end

function replc_del_bt(request::Payload)    
  resp = Dict()
  sql = """
    DELETE FROM banco_subs 
    WHERE id = $(request.get_number("id_row")) and banco_id = $(request.get_number("bdsel"));"""

  query(sql)

  resp["col_replc"] = get_replc(request.get_number("bdsel"))

  return resp
  
end

function prep_edit_bt(request::Payload)    
  resp = Dict()
  ordem = query("select count(ordem) as count from banco_prep where banco_id=$(request.get_number("bdsel"))") |> first |> x -> x.count + 1

  if request.get_number("id_row") != 0
    sql = """update banco_prep set
            function = '$(request.get("function"))',              
            definition = '$(request.get("definition"))'
          WHERE id = $(request.get_number("id_row")) and banco_id = $(request.get_number("bdsel"));"""    
  else
    sql = """
        INSERT INTO banco_prep 
        (ordem,function,definition,banco_id)
        values
        ($ordem, '$(request.get("function"))', '$(request.get("definition"))', $(request.get_number("bdsel")))"""
  end

  query(sql)

  resp["col_prep"] = get_prep(request.get_number("bdsel"))

  return resp
  
end

function prep_del_bt(request::Payload)  
  resp = Dict()
  sql = """
    DELETE FROM banco_prep 
    WHERE id = $(request.get_number("id_row")) and banco_id = $(request.get_number("bdsel"));"""

  query(sql)

  resp["col_prep"] = get_prep(request.get_number("bdsel"))

  return resp
  
end

end
