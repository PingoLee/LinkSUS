module Pag_config_rel

using Stipple, StippleUI
using Unicode
using StipplePlotly
using Genie.Renderer.Json
using SQLite, DataFrames, CSV

db = SQLite.DB(joinpath("data", "linksus.db"))

@mixin(@__MODULE__)

export Config_rel

# tables columns
const col_def = [
  Dict("name" => "id", "label" => "id", "align" => "left", "field" => "id"), 
  Dict("name" => "ordem", "label" => "Ordem", "align" => "left", "field" => "ordem"),  
  Dict( "name" => "col", "label" => "Variável", "field" => "col", "align" => "left"),
  Dict( "name" => "obrig", "label" => "Obrig", "field" => "obrig", "align" => "center"),
  Dict( "name" => "actions", "label" => "Ação", "field" => "", "align" =>"center")
]

const col_replc_def = [
  Dict("name" => "id", "label" => "id", "align" => "left", "field" => "id"), 
  Dict("name" => "antigo", "label" => "Tx. orig.", "align" => "left", "field" => "antigo", "sortable" => true),  
  Dict("name" => "novo", "label" => "Tx. novo", "field" => "novo", "align" => "left", "sortable" => true),
  Dict("name" => "actions", "label" => "Ação", "field" => "", "align" =>"center")
]

const col_prep_def = [
  Dict("name" => "id", "label" => "id", "align" => "left", "field" => "id"), 
  Dict("name" => "ordem", "label" => "Ordem", "align" => "left", "field" => "ordem"), 
  Dict("name" => "function", "label" => "Função", "align" => "left", "field" => "function"),  
  Dict("name" => "definition", "label" => "Definição", "field" => "definition", "align" => "left"),
  Dict("name" => "actions", "label" => "Ação", "field" => "", "align" =>"center")
]



function get_bd(loc)
  local sql = """
    select id, col, obrig, ordem
    from 
  """
  local df = DBInterface.execute(db, "select * from banco_cols where banco_id=$loc") |> DataFrame
  df.obrig = map(x -> x == 1, df.obrig)
  local c = [] 
  for item in eachrow(df)   
      push!(c, Dict(pairs(NamedTuple(item))))  
  end  
  return c
end

function get_crz(loc)
  local df = DBInterface.execute(db, "select * from opc_cruz_rel where opc_cruz_id=$loc") |> DataFrame
  df.obrig = map(x -> x == 1, df.obrig)
  local c = [] 
  for item in eachrow(df)   
      push!(c, Dict(pairs(NamedTuple(item))))  
  end  
  return c
end

function get_replc(loc)
  local df = DBInterface.execute(db, "select * from banco_subs where banco_id=$loc") |> DataFrame  
  local c = [] 
  for item in eachrow(df)   
      push!(c, Dict(pairs(NamedTuple(item))))  
  end  
  return c
end

function get_rel(loc)
  local df = DBInterface.execute(db, "select id, nome from opc_cruz_rel where opc_cruz_id=$loc") |> DataFrame  
  local c = [] 
  for item in eachrow(df)   
      push!(c, Dict(pairs(NamedTuple(item))))  
  end  
  return c
end


function get_crz()
  local df1 = DBInterface.execute(db, "select * from opc_cruzamento") |> DataFrame
  local c = [] 
  for bd in eachrow(df1)   
      push!(c, Dict(pairs(NamedTuple(bd))))  
  end  
  return c
end

@reactive mutable struct Config_rel <: ReactiveModel
  # comoun
  col_def::R{Vector} = col_def; vis_cols::R{Vector} = ["ordem", "col", "obrig", "actions"]
  
  # table bd1
  col_b1_imp::R{Vector} = [];  col_b1_filter::R{String} = ""
  show_b1::R{Bool} = false; b1_row::R{Dict} = Dict(); insert_b1_bt::R{Bool} = false

  # select rel
  list_crz::R{Vector} = get_crz(); selcrz::R{Any} = ""; dict_crz::R{Dict} = Dict()
  list_rel::R{Vector} = []; selrel::R{Any} = ""; obs_rel::R{String} = ""; info_rel::R{Dict} = Dict() 
  show_rel::R{Bool} = false; insert_rel_bt::R{Bool} = false; edit_rel_bt::R{Bool} = false; save_rel_bt::R{Bool} = false
 
end

#Stipple.js_mounted(::Config_rel) = watchplots()

# Stipple.js_watch(app::Config_rel) = raw"""
#     cruzamento: function (val, oldval) {#       
#       }      
#     }
#   """

Stipple.js_methods(m::Config_rel) = raw"""  
  insert_new_rel() {   
    if (this.selcrz == "") {
      var qsr = this.$q; 
      notif = qsr.notify({
        color: 'red',     
        icon: 'announcement',
        message: 'Escolha um cruzamento primeiro',
        position:'top'
      });
    } else {
      this.info_rel = {'id':0, 'nome':'', 'obs':''}
      this.show_rel = true;
    }
  },
  edit_rel() {   
    if (this.selcrz == "") {
      var qsr = this.$q; 
      notif = qsr.notify({
        color: 'red',     
        icon: 'announcement',
        message: 'Escolha um relatório primeiro',
        position:'top'
      });
    } else {
      this.edit_rel_bt = true
    }
  }  
  """

function handlers(model::Config_rel)  
  on(model.selcrz) do selcrz
    model.list_rel[] = get_rel(selcrz) 
    model.dict_crz
    size(model.list_rel[], 1) == 0 ? model.selrel[] = "" :  model.selrel[] = 1
  end

  onbutton(model.edit_rel_bt) do 
    df = DBInterface.execute(db, "select id, nome, obs from opc_cruz_rel where id=$(model.selrel[])") |> DataFrame
    
    model.obs_rel[] = df[1, :obd]



    model.col_b1_imp[] = get_bd(model.)

  end

  onbutton(model.save_rel_bt) do 
    println(model.info_rel[])

    if model.info_rel[]["id"] != 0
      sql = """update opc_cruz_rel set
              nome = '$(model.info_rel[]["nome"])',              
              obs = '$(model.info_rel[]["obs"])'
            WHERE id = $(model.info_rel[]["id"]) and opc_cruz_id = $(model.selcrz[]);"""    
    else
      sql = """
          INSERT INTO opc_cruz_rel 
          (nome,obs,opc_cruz_id)
          values
          ('$(model.info_rel[]["nome"])', '$(model.info_rel[]["obs"])', $(model.selcrz[]))"""
    end

    #println(sql)
    DBInterface.execute(db, sql)

    #println(model.bdsel[])

    model.list_rel[] = get_rel(model.selcrz[])
    
  end

  model
end

end
