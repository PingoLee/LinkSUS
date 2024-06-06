module Pag_config

using Stipple, StippleUI
using Unicode
using StipplePlotly
using Genie.Renderer.Json
using SQLite, DataFrames, CSV

db = SQLite.DB(joinpath("data", "linksus.db"))

# @mixin(@__MODULE__)

export Config

# tables columns
const col_def = [
  Dict("name" => "id", "label" => "id", "align" => "left", "field" => "id"), 
  Dict("name" => "ordem", "label" => "Ordem", "align" => "left", "field" => "ordem"),  
  Dict( "name" => "col", "label" => "Variável", "field" => "col", "align" => "left"),
  Dict( "name" => "function", "label" => "Função", "field" => "function", "align" => "left"),
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

# Dicionário para definição das váriaveis chave
const col_obr = 
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



function get_cols(loc)
  local df = DBInterface.execute(db, "select * from banco_cols where banco_id=$loc") |> DataFrame
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

function get_prep(loc)
  local df = DBInterface.execute(db, "select * from banco_prep where banco_id=$loc") |> DataFrame  
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

@old_reactive! mutable struct Config <: ReactiveModel
  # tabela colunas
  col_imp::R{Vector} = []; col_def::R{Vector} = col_def; col_filter::R{String} = ""; vis_cols::R{Vector} = ["ordem", "col", "function", "obrig", "actions"]
  col_obr::Dict = col_obr; show_dialog::R{Bool} = false; edit_row::R{Dict} = Dict(); edit_bt::R{Bool} = false; del_bt::R{Bool} = false; obrig_bt::R{Bool} = false
  show_mul_col::R{Bool} = false; mult_data::R{String} = ""; mult_bt::R{Bool} = false

  # tables replcacing
  col_replc::R{Vector} = []; col_replc_def::R{Vector} = col_replc_def; col_replc_filter::R{String} = ""; vis_cols_replc::R{Vector} = ["antigo", "novo", "actions"]
  show_replc::R{Bool} = false; replc_edit_row::R{Dict} = Dict(); replc_edit_bt::R{Bool} = false; replc_del_bt::R{Bool} = false

  # tables pre-processing
  col_prep::R{Vector} = []; col_prep_def::R{Vector} = col_prep_def; vis_cols_prep::R{Vector} = ["ordem", "function", "definition", "actions"]
  show_prep::R{Bool} = false; prep_edit_row::R{Dict} = Dict(); prep_edit_bt::R{Bool} = false; prep_del_bt::R{Bool} = false


  # bancos
  bds_list::R{Vector} = get_bds(); bdsel::R{Any} = missing; bdobs::R{String} = ""; bdobs_bt::R{Bool} = false

 
end

#Stipple.js_mounted(::Config) = watchplots()

# Stipple.js_watch(app::Config) = raw"""
#     cruzamento: function (val, oldval) {#       
#       }      
#     }
#   """

Stipple.js_methods(m::Config) = raw"""  
  obrigRow(props) {   
    this.edit_row = Object.assign({}, props.row);    
    this.obrig_bt = true;
  },
  editRow(props) { 
    //console.log(props)
    this.edit_row = Object.assign({}, props.row);   
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
  },
  del_col(props) {     
    this.edit_row = Object.assign({}, props.row);   
    this.del_bt = true;
  },
  add_mult_var() {
    if (this.bdsel == null){
      var qsr = this.$q; 
      notif = qsr.notify({
        color: 'red',     
        icon: 'announcement',
        message: 'Escolha um banco primeiro',
        position:'center'
      });
    } else if (this.col_imp.length < 8){
        var qsr = this.$q; 
        notif = qsr.notify({
          color: 'red',     
          icon: 'announcement',
          message: 'Você precisa informar as 8 primeiras variáveis antes de usar essa opção',
          position:'center'
        });
      } else {
      this.show_mul_col = true;
    }    
  },
  edit_mult_var() {
    if (this.bdsel == null){
      var qsr = this.$q; 
      notif = qsr.notify({
        color: 'red',     
        icon: 'announcement',
        message: 'Escolha um banco primeiro',
        position:'center'
      });
    } else {
      this.mult_bt = true;
    }    
  },
  add_replc_col() {   
    if (this.bdsel == null){
      var qsr = this.$q; 
      notif = qsr.notify({
        color: 'red',     
        icon: 'announcement',
        message: 'Escolha um banco primeiro',
        position:'center'
      });
    } else {
      this.replc_edit_row = {"id": 0, "antigo":"", "novo":""};
      this.show_replc = true;
    }    
  },
  edit_replc_col(props) {     
    this.replc_edit_row = Object.assign({}, props.row);   
    this.show_replc = true;
  },
  del_replc_col(props) {     
    this.replc_edit_row = Object.assign({}, props.row);   
    this.replc_del_bt = true;
  },
  add_prep_col() {   
    if (this.bdsel == null){
      var qsr = this.$q; 
      notif = qsr.notify({
        color: 'red',     
        icon: 'announcement',
        message: 'Escolha um banco primeiro',
        position:'center'
      });
    } else {
      this.prep_edit_row = {"id": 0, "function":"", "definition":""};
      this.show_prep = true;
    }    
  },
  edit_prep_col(props) {     
    this.prep_edit_row = Object.assign({}, props.row);   
    //console.log(this.prep_edit_row);
    this.show_prep = true;
  },
  del_prep_col(props) {     
    this.prep_edit_row = Object.assign({}, props.row);   
    this.prep_del_bt = true;
  } 
  """

function handlers(model::Config)  
  onbutton(model.bdobs_bt) do     
    sql = """UPDATE bancos
                SET 
                obs = '$(model.bdobs[])'
                WHERE id = $(model.bdsel[]);"""

    DBInterface.execute(db, sql)    
  end 

  on(model.bdsel) do tb
    model.col_imp[] = get_cols(tb)
    model.col_replc[] = get_replc(tb)
    model.col_prep[] = get_prep(tb)

    sql = """select obs from bancos                
                WHERE id = $tb;"""

    df = DBInterface.execute(db, sql) |> DataFrame

    ismissing(df[1, :obs]) ? model.bdobs[] = "" : model.bdobs[] = (df[1, :obs])
    
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

    #println(sql)
    DBInterface.execute(db, sql)

    #println(model.bdsel[])

    model.col_imp[] = get_cols(model.bdsel[])
    
  end

  onbutton(model.del_bt) do 
    println(model.edit_row[])
    
    sql = """
      DELETE FROM banco_cols 
      WHERE id = $(model.edit_row[]["id"]) and banco_id = $(model.bdsel[]);"""
  
    #println(sql)
    DBInterface.execute(db, sql)

    #println(model.bdsel[])
    model.col_imp[] = get_cols(model.bdsel[])
    
  end

  onbutton(model.mult_bt) do 
    #println(model.mult_data[])
    vars = split(model.mult_data[], ",")
    vals = [] 
    ordem = size(model.col_imp[], 1)
    for item in vars
      ordem += 1
      push!(vals, "($ordem, '$item', null, true, $(model.bdsel[]))")
    end  
    sql = """
          INSERT INTO banco_cols 
          (ordem,col,function,obrig,banco_id)
          values
          $(join(vals, ","))"""

    #println(sql)
    DBInterface.execute(db, sql)

    model.mult_data[] = ""
    model.col_imp[] = get_cols(model.bdsel[])
  end

  onbutton(model.obrig_bt) do    
    sql = """update banco_cols set           
            obrig = $(model.edit_row[]["obrig"])
          WHERE id = $(model.edit_row[]["id"]) and banco_id = $(model.bdsel[]);"""    
   
    DBInterface.execute(db, sql)    
  end

  onbutton(model.replc_edit_bt) do 
    println(model.replc_edit_row[])
    
    if model.replc_edit_row[]["id"] != 0
      sql = """update banco_subs set
              antigo = '$(model.replc_edit_row[]["antigo"])',              
              novo = '$(model.replc_edit_row[]["novo"])'
            WHERE id = $(model.replc_edit_row[]["id"]) and banco_id = $(model.bdsel[]);"""    
    else
      sql = """
          INSERT INTO banco_subs 
          (antigo,novo,banco_id)
          values
          ('$(model.replc_edit_row[]["antigo"])', '$(model.replc_edit_row[]["novo"])', $(model.bdsel[]))"""
    end

    #println(sql)
    DBInterface.execute(db, sql)

    #println(model.bdsel[])

    model.col_replc[] = get_replc(model.bdsel[])
    
  end

  onbutton(model.replc_del_bt) do 
    println(model.replc_edit_row[])
    
    sql = """
      DELETE FROM banco_subs 
      WHERE id = $(model.replc_edit_row[]["id"]) and banco_id = $(model.bdsel[]);"""
  
    #println(sql)
    DBInterface.execute(db, sql)

    #println(model.bdsel[])
    model.col_replc[] = get_replc(model.bdsel[])
    
  end

  onbutton(model.prep_edit_bt) do 
    println(model.prep_edit_row[])
    ordem = size(model.col_prep[], 1)+1

    if model.prep_edit_row[]["id"] != 0
      sql = """update banco_prep set
              function = '$(model.prep_edit_row[]["function"])',              
              definition = '$(model.prep_edit_row[]["definition"])'
            WHERE id = $(model.prep_edit_row[]["id"]) and banco_id = $(model.bdsel[]);"""    
    else
      sql = """
          INSERT INTO banco_prep 
          (ordem,function,definition,banco_id)
          values
          ($ordem, '$(model.prep_edit_row[]["function"])', '$(model.prep_edit_row[]["definition"])', $(model.bdsel[]))"""
    end

    #println(sql)
    DBInterface.execute(db, sql)

    #println(model.bdsel[])

    model.col_prep[] = get_prep(model.bdsel[])
    
  end

  onbutton(model.prep_del_bt) do 
    println(model.prep_edit_row[])
    
    sql = """
      DELETE FROM banco_prep 
      WHERE id = $(model.prep_edit_row[]["id"]) and banco_id = $(model.bdsel[]);"""
  
    #println(sql)
    DBInterface.execute(db, sql)

    #println(model.bdsel[])
    model.col_prep[] = get_prep(model.bdsel[])
    
  end

  model
end

end
