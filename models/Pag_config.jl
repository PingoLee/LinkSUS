module Pag_config

using Stipple, StippleUI
using Unicode
using StipplePlotly
using Genie.Renderer.Json
using SQLite, DataFrames, CSV

db = SQLite.DB(joinpath("data", "linksus.db"))

@mixin(@__MODULE__)

export Config

col_def = [
  Dict("name" => "id", "label" => "id", "align" => "left", "field" => "id", "sortable" => true), 
  Dict("name" => "ordem", "label" => "Ordem", "align" => "left", "field" => "ordem"),  
  Dict( "name" => "col", "label" => "Coluna", "field" => "col", "align" => "left"),
  Dict( "name" => "function", "label" => "Função", "field" => "function", "align" => "left"),
  Dict( "name" => "actions", "label" => "Ação", "field" => "", "align" =>"center")
]

#const table_options = DataTableOptions(columns = Column(["id", "col", "function", "actions"]))

function get_cols(loc)
  local df = DBInterface.execute(db, "select * from banco_cols where banco_id=$loc") |> DataFrame
  local c = [] 
  for item in eachrow(df)   
      push!(c, Dict(pairs(NamedTuple(item))))  
  end  
  return c
end


function get_bds()
  local df1 = DBInterface.execute(db, "select * from bancos") |> DataFrame
  local c = [] 
  for bd in eachrow(df1)   
      push!(c, Dict(pairs(NamedTuple(bd))))  
  end  
  return c
end

@reactive mutable struct Config <: ReactiveModel
  #tabela colunas
  col_imp::R{Vector} = []; col_def::R{Vector} = col_def; vis_cols::R{Vector} = ["ordem", "col", "function", "actions"]

  # Buttons
  bt_ini::R{Bool} = false

  # bancos
  bds_list::R{Vector} = get_bds(); bdsel::R{Any} = 1; bdobs::R{String} = ""; bdobs_bt::R{Bool} = false

 
end

Stipple.js_mounted(::Config) = watchplots()

# Stipple.js_watch(app::Config) = raw"""
#     cruzamento: function (val, oldval) {
#       if ((oldval != "") && ((this.client_file1 != null) || (this.client_file2 != null))){
#         this.$q.notify({
#           color: 'green',
#           textColor: 'yellow-14',
#           icon: 'warning',
#           message: 'Você mudou o metodo de cruzamento, escolha os bancos de acordo com esse método.'
#         })
#       }      
#     },
#     row_rev: function (val, oldval) {
#       //alert(val)
#       if ((val !== null) && (this.max_rev !=0) && (this.row_rev < 1)) {
#         this.row_rev = 1
#       } else  if ((this.max_rev !=0) && (this.row_rev > this.max_rev)) {
#         this.row_rev = this.max_rev
#       }       
#     }        
#   """

Stipple.js_methods(m::Config) = raw"""  
  editRow(props) {     
    alert(props.row.id)
    console.log(props)
  }
  """

function handlers(model::Config)  
  onbutton(model.bdobs_bt) do 
    print("foi")
    sql = """UPDATE bancos
                SET 
                obs = '$(model.bdobs[])'
                WHERE id = $(model.bdsel[]);"""

    DBInterface.execute(db, sql)    
  end 

  on(model.bdsel) do tb
    model.col_imp[] = get_cols(tb)
    #print(model.bds_list[])
    for item in model.bds_list[]
      if item[:id] == tb 
        print(item[:obs])
        ismissing(item[:obs]) ? model.bdobs[] = "" : model.bdobs[] = item[:obs]
        break
      end
    end
    
  end 

  model
end

end
