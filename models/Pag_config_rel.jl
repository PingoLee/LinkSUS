module Pag_config_rel

using Stipple, StippleUI
using Unicode
using StipplePlotly
using Genie.Renderer.Json
using SQLite, DataFrames, CSV
import Genie.Assets.add_fileroute

db = SQLite.DB(joinpath("data", "linksus.db"))

# @mixin(@__MODULE__)

export Config_rel


add_fileroute(StippleUI.assets_config, "Sortable.min.js", basedir = pwd())
add_fileroute(StippleUI.assets_config, "vuedraggable.umd.min.js", basedir = pwd())
add_fileroute(StippleUI.assets_config, "vuedraggable.umd.min.js.map", type = "js", basedir = pwd())

draggabletree_deps() = [
    script(src = "https://cdnjs.cloudflare.com/ajax/libs/Sortable/1.15.0/Sortable.min.js")
    script(src = """https://cdnjs.cloudflare.com/ajax/libs/Vue.Draggable/2.24.3/vuedraggable.umd.js""")
]

Stipple.DEPS[:vuedraggable] = draggabletree_deps

# tables columns
const col_def = [
  Dict("name" => "id", "label" => "id", "align" => "left", "field" => "id"), 
  Dict("name" => "ordem", "label" => "Ordem", "align" => "left", "field" => "ordem"),  
  Dict( "name" => "col", "label" => "Variável", "field" => "col", "align" => "left"), 
  Dict( "name" => "inrel", "label" => "Inserir", "field" => "inrel", "align" =>"center")
]

const col_cz_def = [
  Dict("name" => "id", "label" => "id", "align" => "left", "field" => "id"), 
  Dict("name" => "ordem", "label" => "Ordem", "align" => "left", "field" => "ordem"),  
  Dict("name" => "var_org_id", "label" => "var_org_id", "align" => "left", "field" => "var_org_id"), 
  Dict("name" => "var_org", "label" => "Origem", "align" => "left", "field" => "var_org"), 
  Dict("name" => "var_rel", "label" => "Relatório", "align" => "left", "field" => "var_rel"),  
  Dict("name" => "bd", "label" => "Banco", "align" => "left", "field" => "bd"),
  Dict("name" => "actions", "label" => "Ação", "field" => "", "align" =>"center")
]

const col_pos_def = [
  Dict("name" => "id", "label" => "id", "align" => "left", "field" => "id"), 
  Dict("name" => "ordem", "label" => "Ordem", "align" => "left", "field" => "ordem"), 
  Dict("name" => "function", "label" => "Função", "align" => "left", "field" => "function"),  
  Dict("name" => "definition", "label" => "Definição", "field" => "definition", "align" => "left"),
  Dict("name" => "actions", "label" => "Ação", "field" => "", "align" =>"center")
]

const col_avan_def = [
  Dict("name" => "id", "label" => "id", "align" => "left", "field" => "id"), 
  Dict("name" => "ordem", "label" => "Ordem", "align" => "left", "field" => "ordem"), 
  Dict("name" => "nome", "label" => "Nome", "align" => "left", "field" => "nome"), 
  Dict("name" => "function", "label" => "Função", "align" => "left", "field" => "function"),  
  Dict("name" => "definition", "label" => "Definição", "field" => "definition", "align" => "left"),
  Dict("name" => "actions", "label" => "Ação", "field" => "", "align" =>"center")
]

# colect sql informations
function get_bd(loc,rel)
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
  local df = DBInterface.execute(db, sql) |> DataFrame
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
  local df = DBInterface.execute(db, sql) |> DataFrame  

  i = 1
  for row in eachrow(df)
    if row.ordem != i
      sql = """UPDATE rel_cols
        SET 
        ordem = '$(i)'
        WHERE id = '$(row.id)';"""

      DBInterface.execute(db, sql)
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
  local df = DBInterface.execute(db, sql) |> DataFrame  
  #println(df)
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

function get_pos(loc)
  local df = DBInterface.execute(db, "select * from rel_pos where rel_id=$loc") |> DataFrame  
  local c = [] 
  for item in eachrow(df)   
      push!(c, Dict(pairs(NamedTuple(item))))  
  end  
  return c
end

"Pega lista de relatórios avançados"
function get_avan(loc)
  local df = DBInterface.execute(db, "select * from rel_avan where rel_id=$loc") |> DataFrame  
  local c = [] 
  for item in eachrow(df)   
      push!(c, Dict(pairs(NamedTuple(item))))  
  end  
  return c
end

function get_crz_dict(loc)
  local sql = """
    select 
      tb.*,
      b1.nome as b1,
      b2.nome as b2
     from opc_cruzamento as tb 
      left join bancos as b1 on b1.id = tb.b1_id
      left join bancos as b2 on b2.id = tb.b2_id
     where tb.id=$loc"""
  local df = DBInterface.execute(db, sql) |> DataFrame  
  return Dict(pairs(NamedTuple(df[1, :])))
end

@old_reactive! mutable struct Config_rel <: ReactiveModel
  # comoun
  col_def::R{Vector} = col_def; col_edit_row::R{Dict} = Dict(); vis_cols::R{Vector} = ["ordem", "col", "obrig", "inrel"]
  col_bt::R{Bool} = false

  # table bd1
  col_b1_imp::R{Vector} = []; col_b1_filter::R{String} = ""
  
  # table bd2
  col_b2_imp::R{Vector} = []; col_b2_filter::R{String} = ""
 
  # select rel (manage info about report selects)
  list_crz::R{Vector} = get_crz(); selcrz::R{Any} = ""; dict_crz::R{Dict} = Dict()
  list_rel::R{Vector} = []; selrel::R{Any} = ""; obs_rel::R{String} = ""; info_rel::R{Dict} = Dict() 
  show_rel::R{Bool} = false; insert_rel_bt::R{Bool} = false; edit_rel_bt::R{Bool} = false; save_rel_bt::R{Bool} = false
  
  # table rel
  col_cz_imp::R{Vector} = []; col_cz_def::R{Vector} = col_cz_def;  col_cz_filter::R{String} = ""; vis_cols_cz::R{Vector} = ["ordem", "var_org", "var_rel", "bd", "actions"]
  show_cz::R{Bool} = false; cz_row::R{Dict} = Dict(); insert_cz_bt::R{Bool} = false; del_cz_bt::R{Bool} = false
  rel_edit_row::R{Dict} = Dict(); save_row_bt::R{Bool} = false; up_row_bt::R{Bool} = false; down_row_bt::R{Bool} = false

  # tables pos-processing
  data_pos::R{Vector} = []; col_pos_def::R{Vector} = col_pos_def; vis_cols_pos::R{Vector} = ["ordem", "function", "definition", "actions"]
  show_pos::R{Bool} = false; pos_edit_row::R{Dict} = Dict(); pos_edit_bt::R{Bool} = false; pos_del_bt::R{Bool} = false

  # tables advanced reports
  data_avan::R{Vector} = []; col_avan_def::R{Vector} = col_avan_def; vis_cols_avan::R{Vector} = ["ordem", "nome", "function", "definition", "actions"]
  show_avan::R{Bool} = false; avan_edit_row::R{Dict} = Dict(); avan_edit_bt::R{Bool} = false; avan_del_bt::R{Bool} = false
end

# Stipple.js_mounted(::Config_rel) = watchplots()

# Stipple.js_watch(app::Config_rel) = raw"""
#     cruzamento: function (val, oldval) {#       
#       }      
#     }
#   """

Stipple.js_methods(m::Config_rel) = raw"""    
  edit_row_rel(props) {   
    if (this.selcrz == "") {
      var qsr = this.$q; 
      notif = qsr.notify({
        color: 'red',     
        icon: 'announcement',
        message: 'Escolha um relatório primeiro',
        position:'top'
      });
    } else {
      this.cz_row = Object.assign({}, props.row);     
      this.show_cz = true
    }
  },
  up_row_rel(props) {   
    if (this.selcrz == "") {
      var qsr = this.$q; 
      notif = qsr.notify({
        color: 'red',     
        icon: 'announcement',
        message: 'Escolha um relatório primeiro',
        position:'top'
      });
    } else {
      this.cz_row = Object.assign({}, props.row); 
      this.up_row_bt = true
    }
  },
  down_row_rel(props) {   
    if (this.selcrz == "") {
      var qsr = this.$q; 
      notif = qsr.notify({
        color: 'red',     
        icon: 'announcement',
        message: 'Escolha um relatório primeiro',
        position:'top'
      });
    } else {
      this.cz_row = Object.assign({}, props.row); 
      this.down_row_bt = true
    }
  },
  del_row_rel(props) {   
    if (this.selcrz == "") {
      var qsr = this.$q; 
      notif = qsr.notify({
        color: 'red',     
        icon: 'announcement',
        message: 'Escolha um relatório primeiro',
        position:'top'
      });
    } else {
      this.cz_row = Object.assign({}, props.row); 
      this.del_cz_bt = true
    }
  },
  insert_new_row_rel(props) {
    if (props.row.inrel == false){
      var qsr = this.$q; 
      notif = qsr.notify({
        color: 'warning',     
        icon: 'warning',
        message: 'Para excluir a variável, clique no botão excluir na tabela a baixo',
        position:'center'
      }); 
      props.row.inrel = true
    } else {      
      this.col_edit_row = Object.assign({}, props.row);   
      this.col_bt = true;
    }
  },
  insert_new_rel() {
    if (this.selcrz == ""){
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
  edit_def_rel() {
    this.edit_rel_bt = true;
    this.show_rel = true;
  },
  add_pos_col() {   
    if (this.selrel == null){
      var qsr = this.$q; 
      notif = qsr.notify({
        color: 'red',     
        icon: 'announcement',
        message: 'Escolha um banco primeiro',
        position:'center'
      });
    } else {
      this.pos_edit_row = {"id": 0, "function":"", "definition":""};
      this.show_pos = true;
    }    
  },
  edit_pos_col(props) {     
    this.pos_edit_row = Object.assign({}, props.row);   
    //console.log(this.pos_edit_row);
    this.show_pos = true;
  },
  del_pos_col(props) {     
    this.pos_edit_row = Object.assign({}, props.row);   
    this.pos_del_bt = true;
  },
  add_avan_col() {   
    if (this.selrel == null){
      var qsr = this.$q; 
      notif = qsr.notify({
        color: 'red',     
        icon: 'announcement',
        message: 'Escolha um banco primeiro',
        position:'center'
      });
    } else {
      this.avan_edit_row = {"id": 0, "function":"", "definition":""};
      this.show_avan = true;
    }    
  },
  edit_avan_col(props) {     
    this.avan_edit_row = Object.assign({}, props.row);   
    //console.log(this.avan_edit_row);
    this.show_avan = true;
  },
  del_avan_col(props) {     
    this.avan_edit_row = Object.assign({}, props.row);   
    this.avan_del_bt = true;
  }
  
  """

function handlers(model::Config_rel)  
  on(model.selcrz) do selcrz
    model.list_rel[] = get_rel(selcrz) 
    # println(model.list_rel[])
    model.dict_crz[] = get_crz_dict(selcrz)
    size(model.list_rel[], 1) == 0 ? (model.selrel[] = ""; model.data_pos[] = []) :  model.selrel[] = model.list_rel[][1][:id]
    println(model.dict_crz[])
  end

  on(model.selrel) do selrel      
    print("foi")
    if selrel != ""
      df = DBInterface.execute(db, "select id, nome, obs from opc_cruz_rel where id=$(selrel)") |> DataFrame
      println(df)
      println(model.dict_crz[])
      if size(df, 1) > 0    
        ismissing(df[1, :obs]) ? model.obs_rel[] = "" : model.obs_rel[] = df[1, :obs]    
  
        model.col_b1_imp[] = get_bd(model.dict_crz[][:b1_id], model.selrel[])
        model.col_b2_imp[] = get_bd(model.dict_crz[][:b2_id], model.selrel[])

        model.col_cz_imp[] = get_rel_cols(selrel)  
        model.data_pos[] = get_pos(selrel)
        model.data_avan[] = get_avan(selrel)
      end

    else
      model.obs_rel[] = ""
      model.col_b1_imp[] = []
      model.col_b2_imp[] = []
      model.col_cz_imp[] = []
      model.data_avan[] = []
    end  
    
  end

  onbutton(model.edit_rel_bt) do 
    println("foi")
    println(model.selrel[])
    df = DBInterface.execute(db, "select * from opc_cruz_rel where id=$(model.selrel[])") |> DataFrame
    print(df)
    if size(df, 1) > 0   
     model.info_rel[] = Dict(pairs(NamedTuple(df[1, :])))
    end
  end

  onbutton(model.col_bt) do  
    sql = """
      select * from rel_cols where var_org_id = $(model.col_edit_row[]["id"]) and cruz_rel_id = $(model.selrel[])
    """
    local df = DBInterface.execute(db, sql) |> DataFrame

    if size(df, 1) == 0    
      ordem = size(model.col_cz_imp[], 1) + 1
      sql = """
        INSERT INTO rel_cols 
            (ordem,var_org_id,var_rel,banco_id,cruz_rel_id)
            values
            ($ordem,'$(model.col_edit_row[]["id"])', null, '$(model.col_edit_row[]["banco_id"])', $(model.selrel[]))
      """   
      DBInterface.execute(db, sql) 
    
    end

    model.col_cz_imp[] = get_rel_cols(model.selrel[])

  end

  # update select report
  onbutton(model.save_rel_bt) do 
    println(model.info_rel[])
    println(model.selcrz[])
    if haskey(model.info_rel[], "id") && model.info_rel[]["id"] != 0
      sql = """update opc_cruz_rel set
              nome = '$(model.info_rel[]["nome"])',              
              obs = '$(model.info_rel[]["obs"])'
            WHERE id = $(model.info_rel[]["id"]) and opc_cruz_id = $(model.selcrz[]);"""    
    else
      print("foi")
      sql = """
          INSERT INTO opc_cruz_rel 
          (nome,obs,opc_cruz_id)
          values
          ('$(model.info_rel[]["nome"])', '$(model.info_rel[]["obs"])', $(model.selcrz[]))"""
    end

    #println(sql)
    DBInterface.execute(db, sql)

    model.col_b1_imp[] = get_bd(model.dict_crz[][:b1_id], model.selrel[])
    model.col_b2_imp[] = get_bd(model.dict_crz[][:b2_id], model.selrel[])
    model.list_rel[] = get_rel(model.selcrz[])
    model.obs_rel[] = model.info_rel[]["obs"]
      
    
  end

  onbutton(model.del_cz_bt) do 
    print(model.cz_row[])
    local sql = """
      delete
      from rel_cols
      where id = $(model.cz_row[]["id"])"""

    println(sql)
    DBInterface.execute(db, sql)
    
    #println(model.bdsel[])

    model.col_b1_imp[] = get_bd(model.dict_crz[][:b1_id], model.selrel[])
    model.col_b2_imp[] = get_bd(model.dict_crz[][:b2_id], model.selrel[])
    model.col_cz_imp[] = get_rel_cols(model.selrel[]) 

  end

  onbutton(model.save_row_bt) do   
    local sql = """
      update rel_cols
      set var_rel = '$(model.cz_row[]["var_rel"])'
      where id = $(model.cz_row[]["id"])"""

    #println(sql)
    DBInterface.execute(db, sql)
    
    model.col_cz_imp[] = get_rel_cols(model.selrel[]) 

  end

  onbutton(model.up_row_bt) do 
    ordem = model.cz_row[]["ordem"]    
    if ordem > 1
      for item in model.col_cz_imp[]
        if item[:ordem] == ordem
          local sql = """
            update rel_cols
            set ordem = $(item[:ordem] - 1)
            where id = $(item[:id])"""
          DBInterface.execute(db, sql)
        elseif item[:ordem] == (ordem - 1)
          local sql = """
            update rel_cols
            set ordem = $(item[:ordem] + 1)
            where id = $(item[:id])"""
          DBInterface.execute(db, sql)      
        end
      end
      model.col_cz_imp[] = get_rel_cols(model.selrel[])
    end
  end

  onbutton(model.down_row_bt) do 
    ordem = model.cz_row[]["ordem"]
    
    if ordem < size(model.col_cz_imp[], 1)
      for item in model.col_cz_imp[]
        if item[:ordem] == ordem
          local sql = """
            update rel_cols
            set ordem = $(item[:ordem] + 1)
            where id = $(item[:id])"""
          DBInterface.execute(db, sql)
        elseif item[:ordem] == (ordem + 1)
          local sql = """
            update rel_cols
            set ordem = $(item[:ordem] - 1)
            where id = $(item[:id])"""
          DBInterface.execute(db, sql)      
        end
      end
      model.col_cz_imp[] = get_rel_cols(model.selrel[])
    end

  end

  onbutton(model.pos_edit_bt) do 
    println(model.pos_edit_row[])
    ordem = size(model.data_pos[], 1)+1
    println(ordem)
    if model.pos_edit_row[]["id"] != 0
      sql = """update rel_pos set
              function = '$(model.pos_edit_row[]["function"])',              
              definition = '$(model.pos_edit_row[]["definition"])'
            WHERE id = $(model.pos_edit_row[]["id"]) and rel_id = $(model.selrel[]);"""    
    else
      sql = """
          INSERT INTO rel_pos 
          (ordem,function,definition,rel_id)
          values
          ($ordem, '$(model.pos_edit_row[]["function"])', '$(model.pos_edit_row[]["definition"])', $(model.selrel[]))"""
    end

    # println(sql)
    DBInterface.execute(db, sql)

    model.data_pos[] = get_pos(model.selrel[])
    
  end

  onbutton(model.pos_del_bt) do 
    println(model.pos_edit_row[])
    
    sql = """
      DELETE FROM rel_pos 
      WHERE id = $(model.pos_edit_row[]["id"]) and rel_id = $(model.selrel[]);"""
  
    #println(sql)
    DBInterface.execute(db, sql)

    #println(model.bdsel[])
    model.data_pos[] = get_pos(model.selrel[])
    
  end

  onbutton(model.avan_edit_bt) do 
    println(model.avan_edit_row[])
    ordem = size(model.data_avan[], 1)+1
    println(ordem)
    if model.avan_edit_row[]["id"] != 0
      sql = """update rel_avan set
              nome = '$(model.avan_edit_row[]["nome"])',
              function = '$(model.avan_edit_row[]["function"])',              
              definition = '$(model.avan_edit_row[]["definition"])'
            WHERE id = $(model.avan_edit_row[]["id"]) and rel_id = $(model.selrel[]);"""    
    else
      sql = """
          INSERT INTO rel_avan 
          (ordem,nome,function,definition,rel_id)
          values
          ($ordem, '$(model.avan_edit_row[]["nome"])', '$(model.avan_edit_row[]["function"])', '$(model.avan_edit_row[]["definition"])', $(model.selrel[]))"""
    end

    println(sql)
    DBInterface.execute(db, sql)

    model.data_avan[] = get_avan(model.selrel[])
    
  end

  onbutton(model.avan_del_bt) do 
    println(model.avan_edit_row[])
    
    sql = """
      DELETE FROM rel_avan 
      WHERE id = $(model.avan_edit_row[]["id"]) and rel_id = $(model.selrel[]);"""
  
    #println(sql)
    DBInterface.execute(db, sql)

    #println(model.bdsel[])
    model.data_avan[] = get_avan(model.selrel[])
    
  end

  model
end

end
