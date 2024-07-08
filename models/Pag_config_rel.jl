module Pag_config_rel

using Unicode
using Genie.Renderer.Json
using DataFrames, CSV

import LinkSUS.SearchLight: query, connection
import LinkSUS: Payload


# draggabletree_deps() = [
#     script(src = "https://cdnjs.cloudflare.com/ajax/libs/Sortable/1.15.0/Sortable.min.js")
#     script(src = """https://cdnjs.cloudflare.com/ajax/libs/Vue.Draggable/2.24.3/vuedraggable.umd.js""")
# ]



# colect sql informations
function get_bd(loc,rel)
  if loc |> ismissing
    return []
  end
  local sql = """
    SELECT
      tb.id,
      tb.banco_id,
      tb.col,
      tb.ordem,
      rel_cols.id as inrel

    FROM banco_cols as tb
      left join rel_cols on rel_cols.var_org_id = tb.id and rel_cols.cruz_rel_id = $(rel)
      
    WHERE tb.banco_id = $(loc)

    order by tb.ordem
  """
  local df = query(sql)
  df.inrel = map(x -> ~ismissing(x), df.inrel)
  #println(df)
  local c = [] 
  for item in eachrow(df)   
      push!(c, Dict(pairs(NamedTuple(item))))  
  end  
  return c
end

function get_rel_cols(loc)
  sql = """
    select
      tb.id,
      tb.ordem
    from rel_cols as tb
      left join banco_cols on banco_cols.id = tb.var_org_id
      left join bancos on bancos.id = tb.banco_id
    where tb.cruz_rel_id = $loc
    order by tb.ordem, tb.id
  """
  local df = query(sql)  

  i = 1
  for row in eachrow(df)
    if row.ordem != i
      sql = """UPDATE rel_cols
        SET 
        ordem = '$(i)'
        WHERE id = '$(row.id)';"""

      query(sql)
    end
    i += 1
  end
  
  sql = """
    select
      tb.id,
      tb.ordem,
      tb.var_org_id,
      banco_cols.col as var_org,
      tb.var_rel,
      bancos.nome as bd

    from rel_cols as tb
      left join banco_cols on banco_cols.id = tb.var_org_id
      left join bancos on bancos.id = tb.banco_id
    where tb.cruz_rel_id = $loc
    order by tb.ordem
  """
  local df = query(sql)  
  #println(df)
  local c = [] 
  for item in eachrow(df)   
      push!(c, Dict(pairs(NamedTuple(item))))  
  end  
  return c
end

function get_rel(loc)
  local df = query("select id, nome from opc_cruz_rel where opc_cruz_id=$loc")  
  local c = [] 
  for item in eachrow(df)   
      push!(c, Dict(pairs(NamedTuple(item))))  
  end  
  return c
end

function get_crz()
  local df1 = query("select * from opc_cruzamento")
  local c = [] 
  for bd in eachrow(df1)   
      push!(c, Dict(pairs(NamedTuple(bd))))  
  end
  resp = Dict()
  resp["get_crz"] = c
  return resp
end

function get_pos(loc)
  local df = query("select * from rel_pos where rel_id=$loc")  
  local c = [] 
  for item in eachrow(df)   
      push!(c, Dict(pairs(NamedTuple(item))))  
  end  
  return c
end

"Pega lista de relatórios avançados"
function get_avan(loc)
  local df = query("select * from rel_avan where rel_id=$loc")  
  local c = [] 
  for item in eachrow(df)   
      push!(c, Dict(pairs(NamedTuple(item))))  
  end  
  return c
end

function get_crz_dict(loc)
  if loc |> ismissing
    return Dict(:b1_id => missing, :b2_id => missing)
  end
  local sql = """
    select 
      tb.*,
      b1.nome as b1,
      b2.nome as b2
     from opc_cruzamento as tb 
      left join bancos as b1 on b1.id = tb.b1_id
      left join bancos as b2 on b2.id = tb.b2_id
     where tb.id=$loc"""
  local df = query(sql)  
  if size(df, 1) == 0
    return Dict(:b1_id => missing, :b2_id => missing)
  end
  return Dict(pairs(NamedTuple(df[1, :])))
end


function selcrz(request::Payload)
  resp = Dict()
  println(get_rel(request.get_number("selcrz")))
  resp["list_rel"] = get_rel(request.get_number("selcrz"))
  resp["dict_crz"] = get_crz_dict(request.get_number("selcrz"))
  resp["selrel"] = size(resp["list_rel"], 1) == 0 ? "" : resp["list_rel"][1][:id]
  
  return resp
end

function selrel(request::Payload)
  selrel = request.get_number("selrel")
  selcrz = request.get_number("selcrz")
  resp = Dict()
  println(request.check(:selrel))
  if request.check(:selrel) 
    df = query("select id, nome, obs from opc_cruz_rel where id=$selrel")
    println(df)
    if size(df, 1) > 0    
      ismissing(df[1, :obs]) ? obs_rel = "" : obs_rel = df[1, :obs]    

      resp[:col_b1_imp] = get_bd(get_crz_dict(selcrz)[:b1_id], selrel)
      resp[:col_b2_imp] = get_bd(get_crz_dict(selcrz)[:b2_id], selrel) 

      resp[:col_cz_imp] = get_rel_cols(selrel)
      resp[:data_pos] = get_pos(selrel)
      resp[:data_avan] = get_avan(selrel)
      resp[:obs_rel] = obs_rel
    end
  end

  if !request.check(:selrel) || haskey(resp, :col_b1_imp) == false
    resp[:obs_rel] = ""
    resp[:col_b1_imp] = []
    resp[:col_b2_imp] = []
    resp[:col_cz_imp] = []
    resp[:data_avan] = []
  end

  return resp
  
end

#   onbutton(model.edit_rel_bt) do 
#     println("foi")
#     println(model.selrel[])
#     df = query("select * from opc_cruz_rel where id=$(model.selrel[])")
#     print(df)
#     if size(df, 1) > 0   
#      model.info_rel[] = Dict(pairs(NamedTuple(df[1, :])))
#     end
#   end

  function col_bt(request::Payload)  
    df = query("select * from rel_cols where var_org_id = $(request.get_number(:id_row)) and cruz_rel_id = $(request.get_number(:selrel))")

    if size(df, 1) == 0    
      ordem = size(get_rel_cols(request.get_number(:selrel)), 1) + 1
      sql = """
        INSERT INTO rel_cols 
            (ordem,var_org_id,var_rel,banco_id,cruz_rel_id)
            values
            ($ordem,'$(request.get(:id_row))', null, '$(request.get_number(:banco_id))', $(request.get_number(:selrel)))
      """   
      query(sql) 
    end

    return Dict("col_cz_imp" => get_rel_cols(request.get_number(:selrel)))

  end

#   # update select report
#   onbutton(model.save_rel_bt) do 
#     println(model.info_rel[])
#     println(model.selcrz[])
#     if haskey(model.info_rel[], "id") && model.info_rel[]["id"] != 0
#       sql = """update opc_cruz_rel set
#               nome = '$(model.info_rel[]["nome"])',              
#               obs = '$(model.info_rel[]["obs"])'
#             WHERE id = $(model.info_rel[]["id"]) and opc_cruz_id = $(model.selcrz[]);"""    
#     else
#       print("foi")
#       sql = """
#           INSERT INTO opc_cruz_rel 
#           (nome,obs,opc_cruz_id)
#           values
#           ('$(model.info_rel[]["nome"])', '$(model.info_rel[]["obs"])', $(model.selcrz[]))"""
#     end

#     #println(sql)
#     query(sql)

#     model.col_b1_imp[] = get_bd(model.dict_crz[][:b1_id], model.selrel[])
#     model.col_b2_imp[] = get_bd(model.dict_crz[][:b2_id], model.selrel[])
#     model.list_rel[] = get_rel(model.selcrz[])
#     model.obs_rel[] = model.info_rel[]["obs"]
      
    
#   end

  function del_cz_bt(request::Payload)
    resp = Dict()
    query("delete from rel_cols where id = $(request.get_number(:id_row))")

    resp["col_b1_imp"] = get_bd(get_crz_dict(request.get_number(:selcrz))[:b1_id], request.get_number(:selrel))
    resp["col_b2_imp"] = get_bd(get_crz_dict(request.get_number(:selcrz))[:b2_id], request.get_number(:selrel))
    resp["col_cz_imp"] = get_rel_cols(request.get_number(:selrel))

    return resp


  end

  function save_row_bt(request::Payload)   
    resp = Dict()
    query("update rel_cols set var_rel = '$(request.get(:var_rel))' where id = $(request.get_number(:id_row))")

    resp["col_cz_imp"] = get_rel_cols(request.get_number(:selrel))

    return resp
  end

  function up_row_bt(request::Payload)   
    resp = Dict()
    ordem = request.get_number(:ordem)
    df = query("select * from rel_cols where cruz_rel_id = $(request.get_number(:selrel)) order by ordem")

    if size(df, 1) > 1
      if ordem > 1
        for item in eachrow(df)
          if item.ordem == ordem
            query("update rel_cols set ordem = $(item.ordem - 1) where id = $(item.id)")
          elseif item.ordem == (ordem - 1)
            query("update rel_cols set ordem = $(item.ordem + 1) where id = $(item.id)")
          end
        end
      end
    end

    resp["col_cz_imp"] = get_rel_cols(request.get_number(:selrel))

    return resp

  end

  function down_row_bt(request::Payload)     
    resp = Dict()
    ordem = request.get_number(:ordem)
    df = query("select * from rel_cols where cruz_rel_id = $(request.get_number(:selrel)) order by ordem")

    if size(df, 1) > 1
      if ordem < size(df, 1)
        for item in eachrow(df)
          if item.ordem == ordem
            query("update rel_cols set ordem = $(item.ordem + 1) where id = $(item.id)")
          elseif item.ordem == (ordem + 1)
            query("update rel_cols set ordem = $(item.ordem - 1) where id = $(item.id)")
          end
        end
      end
    end

    resp["col_cz_imp"] = get_rel_cols(request.get_number(:selrel))

    return resp

  end

#   onbutton(model.pos_edit_bt) do 
#     println(model.pos_edit_row[])
#     ordem = size(model.data_pos[], 1)+1
#     println(ordem)
#     if model.pos_edit_row[]["id"] != 0
#       sql = """update rel_pos set
#               function = '$(model.pos_edit_row[]["function"])',              
#               definition = '$(model.pos_edit_row[]["definition"])'
#             WHERE id = $(model.pos_edit_row[]["id"]) and rel_id = $(model.selrel[]);"""    
#     else
#       sql = """
#           INSERT INTO rel_pos 
#           (ordem,function,definition,rel_id)
#           values
#           ($ordem, '$(model.pos_edit_row[]["function"])', '$(model.pos_edit_row[]["definition"])', $(model.selrel[]))"""
#     end

#     # println(sql)
#     query(sql)

#     model.data_pos[] = get_pos(model.selrel[])
    
#   end

#   onbutton(model.pos_del_bt) do 
#     println(model.pos_edit_row[])
    
#     sql = """
#       DELETE FROM rel_pos 
#       WHERE id = $(model.pos_edit_row[]["id"]) and rel_id = $(model.selrel[]);"""
  
#     #println(sql)
#     query(sql)

#     #println(model.bdsel[])
#     model.data_pos[] = get_pos(model.selrel[])
    
#   end

#   onbutton(model.avan_edit_bt) do 
#     println(model.avan_edit_row[])
#     ordem = size(model.data_avan[], 1)+1
#     println(ordem)
#     if model.avan_edit_row[]["id"] != 0
#       sql = """update rel_avan set
#               nome = '$(model.avan_edit_row[]["nome"])',
#               function = '$(model.avan_edit_row[]["function"])',              
#               definition = '$(model.avan_edit_row[]["definition"])'
#             WHERE id = $(model.avan_edit_row[]["id"]) and rel_id = $(model.selrel[]);"""    
#     else
#       sql = """
#           INSERT INTO rel_avan 
#           (ordem,nome,function,definition,rel_id)
#           values
#           ($ordem, '$(model.avan_edit_row[]["nome"])', '$(model.avan_edit_row[]["function"])', '$(model.avan_edit_row[]["definition"])', $(model.selrel[]))"""
#     end

#     println(sql)
#     query(sql)

#     model.data_avan[] = get_avan(model.selrel[])
    
#   end

#   onbutton(model.avan_del_bt) do 
#     println(model.avan_edit_row[])
    
#     sql = """
#       DELETE FROM rel_avan 
#       WHERE id = $(model.avan_edit_row[]["id"]) and rel_id = $(model.selrel[]);"""
  
#     #println(sql)
#     query(sql)

#     #println(model.bdsel[])
#     model.data_avan[] = get_avan(model.selrel[])
    
#   end

#   model
# end

end
