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

# Dicionário para definição das váriaveis chave
col_obr = 
  Dict(
    1 => "Número que o sistema dá para o registro (ex.: número da notificação)", 
    2 => "Nome do cidadão", 
    3 => "Nome da mãe do cidadão",
    4 => "Data de nascimento",
    5 => "Data do registro no sistema (ex.: data da notificação)",
    6 => "Sexo",
    7 => "Código do IBGE (6 dígitos) do município de residência",
    8 => "Endereço de residência"
    )


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
  col_obr::Dict = col_obr; show_dialog::R{Bool} = false; edit_row::R{Dict} = Dict(); edit_bt::R{Bool} = false
  # Buttons
  bt_ini::R{Bool} = false

  # bancos
  bds_list::R{Vector} = get_bds(); bdsel::R{Any} = missing; bdobs::R{String} = ""; bdobs_bt::R{Bool} = false

 
end

#Stipple.js_mounted(::Config) = watchplots()

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
    //console.log(props)
    this.edit_row = Object.assign({}, props.row);
    if (this.edit_row.obrig == 1){
      this.edit_row.obrig = true;
    }else{
      this.edit_row.obrig = false;
    }
    this.show_dialog = true;
  },
  add_col() {   
    if (this.bdsel == null){
      var qsr = this.$q; 
      notif = qsr.notify({
        color: 'red',     
        icon: 'announcement',
        message: 'Escolha um banco primeiro',
        position:'center'
      });
    } else {
      this.edit_row = {"id": 0, "ordem":this.col_imp.length + 1, "col":"", "function":"", 'obrig':true};
      this.show_dialog = true;
    }    
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

  onbutton(model.edit_bt) do 
    println(model.edit_row[])
    isnothing(model.edit_row[]["function"]) ? func = "null" : func = "'$(model.edit_row[]["function"])'"
    
    if model.edit_row[]["id"] != 0
      sql = """update banco_cols set
              col = '$(model.edit_row[]["col"])',
              function = $(func),
              obrig = $(model.edit_row[]["obrig"])
            WHERE id = $(model.edit_row[]["id"]) and banco_id = $(model.bdsel[]);"""    
    else
      sql = """
          INSERT INTO banco_cols 
          (col,function,obrig,ordem,banco_id)
          values
          ('$(model.edit_row[]["col"])', $(func),$(model.edit_row[]["obrig"]),$(model.edit_row[]["ordem"]),
          $(model.bdsel[]))"""
    end

    println(sql)
    DBInterface.execute(db, sql)

    println(model.bdsel[])

    model.col_imp[] = get_cols(model.bdsel[])
    
  end

  model
end

end
