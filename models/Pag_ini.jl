module Pag_ini

using Stipple, StippleUI
using Unicode
using StipplePlotly
using Genie.Renderer.Json
using SQLite, DataFrames, CSV, XLSX
using StringEncodings, Dates
using Revise

include("../lib/importadores.jl")
includet("../lib/importadores.jl")
using .importadores
include("../lib/linkage_f.jl")
using .linkage_f
include("../lib/relatorio.jl")
includet("../lib/relatorio.jl")
using .relatorio

using PrecompileTools


const ALL = "All"
const db = SQLite.DB(joinpath("data", "linksus.db"))
freq_pn = DataFrame(CSV.File(open(read, joinpath("data", "linksus", "freq", "freq_pn.csv"))))
freq_pn.pn = map(x -> string(x), freq_pn.pn)
freq_sn = DataFrame(CSV.File(open(read, joinpath("data", "linksus", "freq", "freq_sn.csv"))))
freq_sn.sn = map(x -> string(x), freq_sn.sn)
freq_un = DataFrame(CSV.File(open(read, joinpath("data", "linksus", "freq", "freq_un.csv"))))
freq_un.un = map(x -> string(x), freq_un.un)
freq_pnm = DataFrame(CSV.File(open(read, joinpath("data", "linksus", "freq", "freq_pnm.csv"))))
freq_pnm.pnm = map(x -> string(x), freq_pnm.pnm)
freq_unm = DataFrame(CSV.File(open(read, joinpath("data", "linksus", "freq", "freq_unm.csv"))))
freq_unm.unm = map(x -> string(x), freq_unm.unm)

export Importar

function cruzamentos()
  df = DBInterface.execute(db, "select * from opc_cruzamento") |> DataFrame
  local c = [] 
  for item in eachrow(df)   
      push!(c, Dict(pairs(NamedTuple(item))))  
  end  
  return c

end

function cruzamento(crz)
  df = DBInterface.execute(db, "select tb.id, b1.abrev as b1, b2.abrev as b2 from opc_cruzamento as tb inner join bancos as b1 on b1.id = tb.b1_id inner join bancos as b2 on b2.id = tb.b2_id  where tb.id='$crz'") |> DataFrame  
  return df[1, :]
end

function insert_st_crz_dict(loc)
  local sql = """
  INSERT INTO st_cruz (id)
  VALUES ($loc);"""
  DBInterface.execute(db, sql)    
end

function get_st_crz_dict(loc)
  local sql = """
    select 
      tb.*,
      crz.*,
      bd1.abrev as b1, bd2.abrev as b2
     from st_cruz as tb 
      left join opc_cruzamento as crz on crz.id = tb.crz_id
      left join bancos as bd1 on bd1.id = crz.b1_id
      left join bancos as bd2 on bd2.id = crz.b2_id
      
     where tb.id=$loc"""
  local df = DBInterface.execute(db, sql) |> DataFrame  
  if size(df, 1) == 0
    return Dict()
  else
    return Dict(pairs(NamedTuple(df[1, :])))
  end
end

function get_st_crz(loc)
  bd = get_st_crz_dict(loc)
  if bd == Dict()
    insert_st_crz_dict(loc)
    bd = get_st_crz_dict(loc) 
  end
  return bd
end

function get_rel(loc)  
  local c = [] 
  if ~ismissing(loc)
    local df = DBInterface.execute(db, "select id, nome from opc_cruz_rel where opc_cruz_id=$loc") |> DataFrame  
    for item in eachrow(df)   
        push!(c, Dict(pairs(NamedTuple(item))))  
    end  
  end
  return c
end

"Pega lista de relatórios avançados"
function get_avan(loc) 
  local c = [] 
  if ~ismissing(loc)
    local df = DBInterface.execute(db, "select * from rel_avan where rel_id=$loc") |> DataFrame  
    for item in eachrow(df)   
        push!(c, Dict(pairs(NamedTuple(item))))  
    end  
  end
  return c
end

"Pega o dicionário do relatório avançados"
function get_avan_dict(loc)
  local sql = """
    select 
      *
     from rel_avan as tb      
     where tb.id=$loc"""

  local df = DBInterface.execute(db, sql) |> DataFrame  
  if size(df, 1) == 0
    return Dict()
  else
    return Dict(pairs(NamedTuple(df[1, :])))
  end
end

function set_st_import_bd(nu::Union{Missing,String};tipo="importar")
  if ismissing(nu) || length.(nu) > 15
    return ""
  else
    if tipo == "importar"
      return "Foram importados " * nu * "  registros"
    else
      return "Foram relacionados " * nu * "  registros"
    end
  end  
end

bd = get_st_crz(1)
println(bd)
# println(get_rel(bd[:selrel]))
# println(set_st_import_bd(bd[:b1_n]))
# println(set_st_import_bd(bd[:rel_n]; tipo="rel"))


@old_reactive! mutable struct Importar <: ReactiveModel
  # Botões
  limpar_tudo_bt::R{Bool} = false; limpar_crz_bt::R{Bool} = false
  conclui_rev_bt::R{Bool} = false; update_model_bt::R{Bool} = false

  # Alerta
  alert::R{Bool} = false; msg::R{String} = ""

  bd::R{Dict} = bd

  # modelo
  cruzamentos::R{Vector} = cruzamentos(); linkado::R{Bool} = bd[:linkado]
  cruzamento::R{Any} = bd[:crz_id]; cruzar::R{Int} = 0
  client_file1 = missing;  client_file2 = missing
  labelb1::R{String} = "Escolha o tipo de cruzamento"; labelb2::R{String} = "Escolha o tipo de cruzamento" 
  textb1::R{String} = set_st_import_bd(bd[:b1_n]); textb2::R{String} = set_st_import_bd(bd[:b2_n])
  importado::R{Bool} = bd[:importado] ; cruzado::R{Bool} = false 

  # variaveis da revisão
  modo_rev::R{Bool} = bd[:modo_rev]; form_rev::R{Dict} = Dict(); row_rev::R{Int} = 0; max_rev::R{Int} = bd[:max_rev]
  cor_rev::R{Dict} = Dict() ; par_rev::R{String} = "-"; rev_unlock::R{Bool} = false

  # variaveis relatório
  list_rel::R{Vector} = get_rel(bd[:selrel]); selrel::R{Any} = bd[:selrel]
  rel_bt_pad::R{Bool} = false; textrel::R{String} = set_st_import_bd(bd[:rel_n]; tipo="rel")

  # relatório avançado
  rel_avan::R{Bool} = false; list_rel_avan::R{Vector} = get_avan(bd[:selrel]); selrel_avan::R{Any} = missing
  rel_bt_avan::R{Bool} = false

  # relatório custon covid
  textext::R{String} = "Clique para carregar o arquivo"; client_file_ext = missing; rel_avan_bt::R{Bool} = false

end



Stipple.js_mounted(::Importar) = raw"""  
  setTimeout(() => {this.update_model_bt = true}, 400);
  if ((this.row_rev == 0) && (this.conclui_rev_bt == false)) {
    this.row_rev = 1
  };
"""

Stipple.js_watch(app::Importar) = raw"""
    cruzamento: function (val, oldval) {
      if ((oldval != "") && ((this.client_file1 != null) || (this.client_file2 != null))){
        this.$q.notify({
          color: 'green',
          textColor: 'yellow-14',
          icon: 'warning',
          message: 'Você mudou o metodo de cruzamento, escolha os bancos de acordo com esse método.'
        })
      }      
    },
    row_rev: function (val, oldval) {
      //alert(val)
      if ((val !== null) && (this.max_rev !=0) && (this.row_rev < 1)) {
        this.row_rev = 1
      } else  if ((this.max_rev !=0) && (this.row_rev > this.max_rev)) {
        this.row_rev = this.max_rev
      }       
    }        
  """

Stipple.js_methods(m::Importar) = raw"""
  rel_nsus_covid_pos_Submit(evt) {       
    var qsr = this.$q;         
    var modelo = this;      
    this.isprocessing = true;
    this.textext = "Aguarde";
    if (this.client_file_ext == null) {
      qsr.notify({
        color: 'red-5',
        textColor: 'white',
        icon: 'warning',
        message: 'Você precisa escolher o arquivo do COE antes de prosseguir'
      });      
      this.isprocessing = false;
    } else {
      notif = qsr.notify({
        type: 'ongoing',     
        message: 'Enviado, aguarde'
      });
      //alert(this.client_file1);
      
      const formData = new FormData(evt.target);
      const data = [];

      axios.post('/rel_nsus_covid_pos',
        formData,
        {
          headers: {
              'Content-Type': 'multipart/form-data'
          }
        }
      ).then(function(resp){          
        modelo.isprocessing = false;
        modelo.textext = "Processamento concluído";
        modelo.msg = resp.data.msg2;
        modelo.alert = true;
        modelo.update_model_bt = true;
        
        notif({
          type: resp.data.cor,   
          message: resp.data.msg      
        });     

      })
      .catch(function(){  
        notif({
          type: 'negative',
          message: 'Algo deu errado'
        })
      });
    
    }
  },
  onSubmit (evt) {     
    var qsr = this.$q;         
    var modelo = this;  
    this.importado = true
    this.isprocessing = true
    this.textb1 = "Aguarde"
    this.textb2 = "Aguarde"
    if ((this.client_file1 == null) || (this.client_file2 == null)) {
      qsr.notify({
        color: 'red-5',
        textColor: 'white',
        icon: 'warning',
        message: 'Você precisa escolher os dois bancos'
      });
      this.importado = false;
      this.isprocessing = false;
    } else {
      notif = qsr.notify({
        type: 'ongoing',     
        message: 'Enviado, aguarde',
        position:'center'
      });
      //console.log( this.client_file1);
      //console.log( this.client_file2);
      //console.log(evt.target);
      
      //var formData = new FormData(evt.target);
      var formData = new FormData();
      //const data = [];

      var cont = 0
      var chave = []
   
      this.client_file1.forEach(file=>{
        cont += 1
        formData.append(`file1_id_${cont}`, file);
        chave.push(`file1_id_${cont}`)
      });        
      
      formData.append("file1_id", chave);
    
      cont = 0
      chave = []
      this.client_file2.forEach(file=>{
        cont += 1
        formData.append(`file2_id_${cont}`, file);
        chave.push(`file2_id_${cont}`)
      });        
      formData.append("file2_id", chave);
        
      formData.append("cruzamento", this.cruzamento);
      
      //console.log(formData)

      axios.post('/sub',
        formData,
        {
          headers: {
              'Content-Type': 'multipart/form-data'
          }
        }
      ).then(function(resp){          
        modelo.isprocessing = false;
        modelo.textb1 = resp.data.textb1;
        modelo.textb2 = resp.data.textb2;
        modelo.update_model_bt = true;

        notif({
          type: resp.data.cor,   
          message: resp.data.msg      
        });        
      })
      .catch(function(){  
        notif({
          type: 'negative',
          message: 'Algo deu errado'
        })
      });

      //alert(this.isprocessing)
    
    }
  },
  onReset () { 
    this.client_file1 = null;
    this.client_file2 = null;  
    this.importado = false;
    this.isprocessing = false;
    this.modo_rev = false;
    this.limpar_tudo_bt = true;
  },
  onCruzar () { 
    var qsr = this.$q;         
    var modelo = this;  
    this.max_rev = 0; this.row_rev = 0
    notif = qsr.notify({
        type: 'ongoing',     
        message: 'Enviado, aguarde',
        position:'center'
      });

    axios.get('/cruzar'       
      ).then(function(resp){  
        //alert(resp.data.max_rev);
        modelo.row_rev = 1;
        modelo.max_rev = resp.data.max_rev;
        modelo.modo_rev = resp.data.modo_rev;
        modelo.linkado = 1;
        modelo.textrel = resp.data.textrel;
        modelo.revisado = resp.data.revisado;     
        modelo.update_model_bt = true;   
        notif({
          type: resp.data.cor,   
          message: resp.data.msg      
        });        
      })
      .catch(function(){  
        notif({
          type: 'negative',
          message: 'Algo deu errado'
        })
      });
  },
  onPar () {
    // é par
    //alert(this.rev_unlock);
    this.rev_unlock = true;
    //alert(this.rev_unlock);
    this.par_rev = "S";
    setTimeout(() => {this.row_rev += 1}, 300);
  },
  onNPar () {
      // não é par
      this.rev_unlock = true;
      //alert(this.rev_unlock)
      this.par_rev = "N";
      setTimeout(() => {this.row_rev += 1}, 300);
  }
  """

function handlers(model::Importar)  

  on(model.cruzamento) do crz   
    loc = cruzamento(crz)
    sql = """
    UPDATE st_cruz as tb
      SET crz_id = $(crz)
    WHERE tb.id = 1; """
    DBInterface.execute(db, sql) 

    model.list_rel[] = get_rel(crz)
    model.bd[] = get_st_crz(1)
  end 

  on(model.selrel) do selrel  
    model.selrel_avan[] = missing
    model.list_rel_avan[] = get_avan(selrel)    
  end 

  onany(model.par_rev, model.rev_unlock) do par_rev, rev_unlock 
    print(rev_unlock)
    if rev_unlock      
      revisa_row_par(model.row_rev[], par_rev)   
    end   
  end

  onbutton(model.limpar_tudo_bt) do 
    DBInterface.execute(db, "DELETE FROM b1_proc")
    DBInterface.execute(db, "DELETE FROM b2_proc")   
    DBInterface.execute(db, "DELETE FROM list_cruz")
    DBInterface.execute(db, "DELETE FROM list_cruz_rv")
    DBInterface.execute(db, "DELETE FROM st_cruz where id = 1")  
    DBInterface.execute(db, """VACUUM "main" """)
    DBInterface.execute(db, """VACUUM "temp" """)
    model.linkado[] = false
    model.bd[] = get_st_crz(1)
    sql = """
    UPDATE st_cruz as tb
      SET crz_id = $(model.cruzamento[])
    WHERE tb.id = 1; """
    DBInterface.execute(db, sql)     
    model.bd[] = get_st_crz(1)
    model.list_rel[] = get_rel(model.cruzamento[])
  end

  onany(model.row_rev, model.max_rev) do row_rev, max_rev
    print(model.row_rev)
    cor_rev = Dict("n" => "green", "nm" => "green", "dn" => "green", "sx" => "green", "ibge" => "green")  
    if max_rev != 0 && row_rev >= 1 && row_rev <= max_rev    
      dict_form = revisa_row(row_rev)
      println(dict_form)
      dist_n = jaro(dict_form["nome1"], dict_form["nome2"])
      dist_n > 98 ? cor_rev["n"] = "green" : dist_n > 82 ? cor_rev["n"] = "yellow-4" : cor_rev["n"] = "red"
      dist_nm = jaro(dict_form["nm_m1"], dict_form["nm_m2"])
      ismissing(dist_nm) ? cor_rev["nm"] = "light-blue" : dist_nm > 98 ? cor_rev["nm"] = "green" : dist_nm > 82 ? cor_rev["nm"] = "yellow-4" : cor_rev["nm"] = "red"
      ismissing(dict_form["distdn"]) ? cor_rev["dn"] = "light-blue" : dict_form["distdn"] > 98 ? cor_rev["dn"] = "green" : dict_form["distdn"] > 82 ? cor_rev["dn"] = "yellow-4" : dict_form["distdn"] > 49 ? cor_rev["dn"] = "orange-7" : cor_rev["dn"] = "red"
      ismissing(dict_form["sexo1"]) || ismissing(dict_form["sexo2"]) ? cor_rev["sx"] = "light-blue" : dict_form["sexo1"] == dict_form["sexo2"] ? cor_rev["sx"] = "green" : cor_rev["sx"] = "red"
      ismissing(dict_form["ibge1"]) || ismissing(dict_form["ibge2"]) ? cor_rev["ibge"] = "light-blue" : dict_form["ibge1"] == dict_form["ibge2"] ? cor_rev["ibge"] = "green" : cor_rev["ibge"] = "red"


      model.rev_unlock[] = false
      model.par_rev[] = dict_form["par_rev"]    
      model.form_rev[] = dict_form
      model.cor_rev[] = cor_rev    
      #println(model.cor_rev[])
    end
  end

  onbutton(model.rel_bt_pad) do
    model.isprocessing[] = 1  

    println(model.bd[])

    println(model.selrel[])

    if ismissing(model.selrel[]) 
      model.msg[] = """Favor escolher um relatório antes de gerar relatório"""
    else
      escrita, escrita_a = gerar_relatorio(db, model.selrel[], model.bd[:b1_id],  model.bd[:b2_id], model.bd[][:nome])    

      print("foi")
      
      folder_path = joinpath(pwd(), "data","reports", model.bd[][:nome])  

      println(folder_path)

      if ~escrita || ~escrita_a
        model.msg[] = """O relatório não foi gerado porque o arquivo está aberto, feche e gere o relatório novamente"""
      else
        model.msg[] = """Cruzamento de dados concluído, você pode encontrar os resultados em $folder_path"""
        try
          run(`explorer.exe $(folder_path)`)
        catch
        end      
      end
    end

    model.alert[] = true
    model.rel_avan[] = true
    model.isprocessing[] = 0

  end

  onbutton(model.conclui_rev_bt) do
    model.isprocessing[] = 1
    model.modo_rev[] = false
    model.list_rel[] = get_rel(model.cruzamento[])
    # grava os dados do banco
    sql = """
      UPDATE st_cruz as tb
      SET modo_rev = 0
      WHERE tb.id = 1; 
    """
    #println(sql)
    
    DBInterface.execute(db, sql)
    model.bd[] = get_st_crz(1)
    model.isprocessing[] = 0
  end

  onbutton(model.update_model_bt) do     
    model.bd[] = get_st_crz(1)
    model.list_rel[] = get_rel(model.cruzamento[])    
  end

  onbutton(model.rel_bt_avan) do
    model.isprocessing[] = 1

    rel_avan = get_avan_dict(model.selrel_avan[])
    getfield(Pag_ini, Symbol(rel_avan[:function]))(rel_avan, get_st_crz(1))

    model.msg[] = """Relatório avançado gerado com sucesso"""
    model.alert[] = true
        
    model.isprocessing[] = 0
  end
   
  model
end

function create_storage_dir(name)
  try
    mkdir(joinpath(@__DIR__, name))    
    @warn "O diretório foi criado" 
  catch    
  end
  return joinpath(@__DIR__, name)
end

# routs
function receb_arquivos()
  global bd = get_st_crz(1)
  resp = Dict()
  csv_save = Dict("file1_id" => "b1", "file2_id" => "b2")
  files = Genie.Requests.filespayload()
  post = Genie.Requests.postpayload()  

  println(post)
  # println(files)

  # println(post[:cruzamento])
  b1 = nothing; b2 = nothing
  try
    b1, b2 = get_sql_bancos_defs(db, post[:cruzamento])
  catch
    resp["cor"] = "negative"
    resp["msg"] = "O cruzamento de dados não foi escolhido" 
    return Json.json(resp)
  end

  fs = []
  # println(Symbol(b1.file))
  # f = files[Symbol(b1.file)]
  if haskey(post, Symbol(b1.file))
    fs0 = split(post[ Symbol(b1.file)], ",")
    for f1 in fs0
      push!(fs, files[f1])
    end
  else
    resp["cor"] = "negative"
    resp["msg"] = "O banco de dados 1 não foi escolhido" 
    return Json.json(resp)
  end

  df1 = missing

  # checa e importa o banco 1
  # println(files[b1.file])
  for f in fs  
    if lowercase(splitext(f.name)[2]) != b1.formato 
      resp["cor"] = "negative"
      resp["msg"] = "O formato do banco de cados " * b1.abrev * " está erradado, o arquivo deve estar no formato " * b1.formato 
      return Json.json(resp)    
    end
    
    write(joinpath("data", "linksus", "bruto", string(b1.file, splitext(f.name)[2])), f.data)
    df = getfield(importadores, Symbol(b1.function))(joinpath("data", "linksus", "bruto", string(b1.file, splitext(f.name)[2]))) # Importa a base de dados como df  

    erro, resp = valida_bancos(db, df, b1, resp)
    erro && (return Json.json(resp))
    
    if ismissing(df1)
      df1 = df
    else
      df1 = append!(df1, df)
    end
  end
  
  formata_proc_bd(db, df1, csv_save, b1) # sobe os dados para o sql, dados apenas de cruzamento

  b1_n = size(df1,1)
  textb1 = "Foram importados $(size(df1,1)) registros"

  println("inicia b2")
  # checa e importa o banco 2 
  fs = []
  if haskey(post, Symbol(b2.file))
    fs0 = split(post[ Symbol(b2.file)], ",")
    for f1 in fs0
      push!(fs, files[f1])
    end
  else
    resp["cor"] = "negative"
    resp["msg"] = "O banco de dados 2 não foi escolhido" 
    return Json.json(resp)
  end

  df1 = missing
  for f in fs  
    if lowercase(splitext(f.name)[2]) != b2.formato 
      resp["cor"] = "negative"
      resp["msg"] = "O formato do banco de cados " * b2.abrev * " está erradado, o arquivo deve estar no formato " * b2.formato 
      return Json.json(resp)    
    end
    
    write(joinpath("data", "linksus", "bruto", string(b2.file, splitext(f.name)[2])), f.data)
    df = getfield(importadores, Symbol(b2.function))(joinpath("data", "linksus", "bruto", string(b2.file, splitext(f.name)[2]))) # Importa a base de dados como df  

    erro, resp = valida_bancos(db, df, b2, resp)
    erro && (return Json.json(resp))
    
    if ismissing(df1)
      df1 = df
    else
      df1 = append!(df1, df)
    end
  end
   
  formata_proc_bd(db, df1, csv_save, b2)
  b2_n = size(df1,1)
  textb2 = "Foram importados $(size(df1,1)) registros"
  
  #impor_arquivos(post[:cruzamento], FILE_PATH)

  md = Base.invokelatest(Importar) # conseguindo coletar o modelo

  # grava os dados do banco
  sql = """
  UPDATE st_cruz as tb
  SET b1_n = '$b1_n', b2_n = '$b2_n', crz_id= $(post[:cruzamento]), importado = 1
  WHERE tb.id = 1; """
  #println(sql)
  DBInterface.execute(db, sql)   
  
  resp["cor"] = "positive"
  resp["msg"] = "Concluído com sucesso" 
  resp["textb1"] = textb1
  resp["textb2"] = textb2
  return Json.json(resp)  
  
end

function processa_notificasus()
  resp = Dict()
  files = Genie.Requests.filespayload()
  post = Genie.Requests.postpayload()

  f = files["file1_id"] # pega dict do file form (file1_id)
 
  if lowercase(splitext(f.name)[2]) != ".xlsx"
    resp["cor"] = "negative"
    resp["msg"] = "O formato do banco de dados está erradado, o arquivo deve estar no formato .xlsx" 
    return Json.json(resp)    
  end

  f = XLSX.readxlsx(IOBuffer(f.data))
  s = f["CONFIRMADOS"]
  df = XLSX.eachtablerow(s) |> DataFrames.DataFrame

  relatorio = get_st_crz(1)[:nome]

  check, msg = rel_nsus_covid_pos(df, relatorio)

  folder_path = joinpath("data", "reports", relatorio)  

  if check == false
    resp["msg2"] = """O relatório não foi gerado porque o arquivo está aberto, feche e gere o relatório novamente"""
  else
    resp["msg2"] = """O relatório do notificasus foi concluído, você pode encontrar os resultados em $folder_path"""
    try
      run(`explorer.exe $(folder_path)`)
    catch
    end      
  end

  resp["cor"] = "positive"
  resp["msg"] = "Concluído com sucesso"   
  return Json.json(resp)

end


# funções acessórias
#Importar banco
"""Formata o banco de dados"""
function formata_proc_bd(db::SQLite.DB, df::DataFrame, csv_save::Dict, row::DataFrameRow)

  insertcols!(df, 1, :index => axes(df, 1))
  
  #Salva arquivo bruto
  open(joinpath("data", "linksus", "importado", string(csv_save[row.file], ".csv")), "w") do io
    CSV.write(io, df, delim=";")
  end  

  lst_new = ["index", "cod", "nome", "nome_mae", "dn", "dr", "sexo", "ibge", "end"] # Nome das colunas do arquivo de cruzamento

  select!(df, [1, 2, 3, 4, 5, 6, 7, 8, 9])

  lst = names(df)

  for i = 2:9
    rename!(df, Dict([lst[i] => lst_new[i]]))
  end

  show(df)
  
  # for row in eachrow(df)
  #   x = row.NM_PACIENT
  #   println(x)
  #   ismissing(x) || x == "" ? missing : filter(x -> isletter(x) || isspace(x),
  #     replace(replace(Unicode.normalize(uppercase(x), stripcc=true, stripmark=true, chartransform=Unicode.julia_chartransform), 
  #     "VIVO" => "", "II" => "I", "PP" => "P", "LL" => "L", "Ç" => "S", "RR" => "R", "TT" => "T", "TH" => "T", 
  #     "SOUZA" => "SOUSA", "Y" => "I", "NN" => "N", "SCH" => "X", "SH" => "X", "PH" => "F", "TH" => "T", "CHR" => "K", "CH" => "X",
  #     " DOS " => " ", " DAS " => " ", " DE " => " ", " DA " => " ", " DO " => " ", " E " => " "), r" +" => " "))
  # end

  df.nome = map(x -> ismissing(x) || x == "" ? missing : filter(x -> isletter(x) || isspace(x),
      replace(replace(Unicode.normalize(uppercase(x), stripcc=true, stripmark=true, chartransform=Unicode.julia_chartransform), 
      "VIVO" => "", "II" => "I", "PP" => "P", "LL" => "L", "Ç" => "S", "RR" => "R", "TT" => "T", "TH" => "T", 
      "SOUZA" => "SOUSA", "Y" => "I", "NN" => "N", "SCH" => "X", "SH" => "X", "PH" => "F", "TH" => "T", "CHR" => "K", "CH" => "X",
      " DOS " => " ", " DAS " => " ", " DE " => " ", " DA " => " ", " DO " => " ", " E " => " "), r" +" => " ")),
    df.nome)

  df.nome = map(x -> ismissing(x) ? missing : replace(replace(replace(replace(replace(replace(replace(x, "RN " => "RN", "NT " => "FM"), r".{0,}F[I,E].{1,2}O M.{0,5} " => "FM"), 
    r"FI.{0,2}O {0,7}" => "RN"), r"RE.{1,4} NA.{1,2}IDO " => "RN"), r"SEM INFORMA.{1,3}O.{0,}" => missing), r"IG.{1,}RADO.{1,}" => missing), r".{0,}IND.{0,2}GENT*.{0,}" => missing), 
    df.nome)

  df.nome_mae = map(x -> ismissing(x) || x == "" ? missing : filter(x -> isletter(x) || isspace(x),
    replace(replace(Unicode.normalize(uppercase(x), stripcc=true, stripmark=true, chartransform=Unicode.julia_chartransform), 
    "VIVO" => "", "II" => "I", "PP" => "P", "LL" => "L", "Ç" => "S", "RR" => "R", "TT" => "T", "TH" => "T", 
    "SOUZA" => "SOUSA", "Y" => "I", "NN" => "N", "SCH" => "X", "SH" => "X", "PH" => "F", "TH" => "T", "CHR" => "K", "CH" => "X",
    " DOS " => " ", " DAS " => " ", " DE " => " ", " DA " => " ", " DO " => " ", " E " => " ", "NAO" => ""), r" +" => " ")),
    df.nome_mae)

  df.nome_mae = map(x -> ismissing(x) || x == "" ? missing : x, df.nome_mae)
  
  insertcols!(df, :ibge, :pnm => "", after=true)
  insertcols!(df, :pnm, :unm => "", after=true)
  insertcols!(df, :pnm, :mnm => "", after=true) 
  insertcols!(df, :pnm, :sxpnm => "", after=true)
  insertcols!(df, :unm, :sxunm => "", after=true)
  insertcols!(df, :ibge, :pn => "", after=true)
  insertcols!(df, :pn, :un => "", after=true)
  insertcols!(df, :pn, :mn => "", after=true) 
  insertcols!(df, :pn, :sn => "", after=true) 
  insertcols!(df, :pn, :sxpn => "", after=true)
  insertcols!(df, :un, :sxun => "", after=true)
  insertcols!(df, :sn, :sxsn => "", after=true)

  for item in eachrow(df)
    if ~ismissing(item.nome_mae)
      nm = split(item.nome_mae, " ")
      item.pnm = nm[1]
      item.unm = nm[length(nm)]
      item.mnm = strip(replace(item.nome_mae, item.pnm => "", item.unm => ""))
      item.sxpnm = soundex_br(item.pnm)
      item.sxunm = soundex_br(item.unm)
    end

    if ~ismissing(item.nome)
      n = split(item.nome, " ")      
      item.pn = n[1]
      item.un = n[length(n)]      
      item.sxpn = soundex_br(item.pn)
      item.sxun = soundex_br(item.un)
      if length(n) > 2 
        item.mn = strip(replace(item.nome, item.pn => "", item.un => ""))
        item.sn = n[2]
        item.sxsn = soundex_br(string(n[2]))
      end
    end

  end

  # show(df)

  filter!([:nome] => x -> ~ismissing(x) && x != "", df)

  # grava dados processados
  open(joinpath("data", "linksus", "importado", string(csv_save[row.file], "_proc" , ".csv")), "w") do io
    CSV.write(io, df, delim=";")
  end  

  DBInterface.execute(db, "DELETE FROM $(string(csv_save[row.file], "_proc"))")
  
  #replace!(df.a, "None" => "c")
  # show(filter([:index] => x -> x == 10329, df))

  SQLite.load!(df, db, string(csv_save[row.file], "_proc"))  
  
    
end

"""Checa e corrige os bancos,
O banco_id é a chave do banco selecionado"""
function valida_bancos(db::SQLite.DB, df1::DataFrame, b1::DataFrameRow, resp::Dict)
    col_b1 = get_sql_bancos_cols(db, b1.id) 
    subs_b1 = get_sql_bancos_subs(db, b1.id)
    prep = get_sql_bancos_prep(db, b1.id)
    
    # faz a checagem dos campos a serem substituídos  
    for item in eachrow(prep)
      println("Tem função")
      println(item)
      getfield(Pag_ini, Symbol(item.function))(df1)
    end
   
    # faz a checagem dos campos a serem substituídos
    for item in eachrow(subs_b1)
      if item.antigo in names(df1)
          rename!(df1, Dict([item.antigo => item.novo]))
      end
    end
    

    #Inicia checagem de colunas
    if setdiff(filter([:obrig] => x -> x == 1, col_b1).col, names(df1)) != []
        resp["cor"] = "negative"
        resp["msg"] = "O banco de dados " * b1.abrev * " não foi escolhido corretamente, o arquivo enviado não apresenta as seguintes colunas: " * string(setdiff(filter([:obrig] => x -> x == 1, col_b1).col, names(df1)))
        return true, resp
    end

    #insere as colunas obrigatórias
    #println(setdiff(filter([:obrig] => x -> x == 0, col_b1).col, names(df1)))
    for col in setdiff(filter([:obrig] => x -> x == 0, col_b1).col, names(df1))    
      insertcols!(df1, 1, col => missing)  
    end

    select!(df1, col_b1.col)

    # faz as conversões necessárias
    for func in eachrow(filter([:function] => x -> ~ismissing(x) && x != "", col_b1))
      df1[!, func.col] = getfield(importadores, Symbol(func.function))(df1, func.col)
    end

    #show(df1, allrows=false)

    #println(names(df1))

    return false, resp

end

"Efetua o cruzameto deterministico"
function linkage_det()
  inicio = now()
  resp = Dict()
  local limar_sms = 170 #CRIAR CONFIGURAÇÃO
  local limiar_nome = 71
  md = Base.invokelatest(Importar)
  println(md.cruzamento[])
  global bd = get_st_crz(1)
  

  df = block_sql_mult(10, bd[:b1_n]) 
  insertcols!(df, 1, :id => axes(df,1))

  #insertcols!(df, 1, :id => axes(df,1))

  show(df)

  #  #println(filter([:id2] => x -> x == 10329, df))
  println(Dates.format(convert(DateTime, now() - inicio), "MM:SS"))

  t_score = now()
  # limpeza
  df.levn = map((x, y) -> levenshtein(x, y, true), df.nome1, df.nome2)
  df.levnm = map((x, y) -> levenshtein(x, y, true), df.nm_m1, df.nm_m2)
  df.distdn = map((x, y) -> dateaval(x, y), df.dn1, df.dn2)
  df.escore = map((x,y,z) -> (ismissing(x) ? 50 : x) + (ismissing(y) ? 50 : y) + (ismissing(z) ? 50 : z) , df.levn, df.levnm, df.distdn)

  filter!([:escore] => x -> x >= limar_sms, df)

  println(Dates.format(convert(DateTime, now() - t_score), "MM:SS"))

  # calcula escores probabilisticos
  t_score = now()
  dfp = calc_prob(DataFrames.select(df, Not([:levn, :levnm, :escore, :dn1, :dn2])), db)
  
  # tipo da abreviação e crianças
  insertcols!(df, :escore, :difday => 0, after=true)
  insertcols!(df, :escore, :abrev => "", after=true)  
  for row in eachrow(df)
    if first(row.nome1, 2) == "RN" || first(row.nome2, 2) == "RN" 
      first(row.nome1, 2) == "RN" && first(row.nome2, 2) == "RN" ? row.abrev = "RN2" : row.abrev = "RN1" 
      if ismissing(row.distdn)
        row.dn1 > row.dn2 ? row.difday = Dates.value.(row.dn1 - row.dn2) : row.difday = Dates.value.(row.dn2 - row.dn1)
      end
    
    elseif first(row.nome1, 2) == "FM" || first(row.nome2, 2) == "FM" 
      first(row.nome1, 2) == "FM" && first(row.nome2, 2) == "FM" ? row.abrev = "RN2" : row.abrev = "RN1" 
      if ismissing(row.distdn)
        row.dn1 > row.dn2 ? row.difday = Dates.value.(row.dn1 - row.dn2) : row.difday = Dates.value.(row.dn2 - row.dn1)
      end

    else
      row.abrev = avalabrev(row.nome1, row.nome2)
    end
  end

  # coloca frequencias ASINC
  # baixa b1 (nomes)
  b1 = checa_nomes(df.id1, "b1")
  b2 = checa_nomes(df.id2, "b2")

  dff = DataFrames.select(df, [:id, :id1, :id2, :dn1, :dn2, :abrev]) # df de frequências
  #show(b1)
  leftjoin!(dff, b1, on=:id1)
  leftjoin!(dff, b2, on=:id2)
  insertcols!(dff, 2, :dt_flag => "")

  show(dff)
  #println(DataFrames.filter([:sn1] => x -> ~ismissing(x) && x == "", dff))
  
  for row in eachrow(dff)    
    if ismissing(row.pn) && row.pn1 == row.pn2
      row.pn = "R"
    elseif row.pn1 != row.pn2
      levenshtein(row.pn1, row.pn2) > limiar_nome ? row.pn = "D0" : row.pn = "D"
    end      
  
    if ismissing(row.sn1) || ismissing(row.sn2) || row.sn1 == "" || row.sn2 == ""
      (ismissing(row.sn1) || row.sn1 == "") && (ismissing(row.sn2) || row.sn2 == "") ? row.sn = "S" : row.sn = "I"
    elseif ismissing(row.sn) && row.sn1 == row.sn2
      row.sn = "R"
    elseif row.sn1 != row.sn2
      levenshtein(row.sn1, row.sn2) > limiar_nome ? row.sn = "D0" : row.sn = "D"
    end      
 
    if ismissing(row.un1) || ismissing(row.un2) || row.un1 == "" || row.un2 == ""
      (ismissing(row.un1) || row.un1 == "") && (ismissing(row.un2) || row.un2 == "") ? row.un = "S" : row.un = "I"
    elseif ismissing(row.un) && row.un1 == row.un2
      row.un = "R"
    elseif row.un1 != row.un2
      levenshtein(row.un1, row.un2) > limiar_nome ? row.un = "D0" : row.un = "D"
    end      

    if ismissing(row.pnm1) || ismissing(row.pnm2) || row.pnm1 == "" || row.pnm2 == ""
      (ismissing(row.pnm1) || row.pnm1 == "") && (ismissing(row.pnm2) || row.pnm2 == "") ? row.pnm = "S" : row.pnm = "I"
    elseif ismissing(row.pnm) && row.pnm1 == row.pnm2
      row.pnm = "R"
    elseif row.pnm1 != row.pnm2
      levenshtein(row.pnm1, row.pnm2) > limiar_nome ? row.pnm = "D0" : row.pnm = "D"
    end     

    if ismissing(row.unm1) || ismissing(row.unm2) || row.unm1 == "" || row.unm2 == ""
      (ismissing(row.unm1) || row.unm1 == "") && (ismissing(row.unm2) || row.unm2 == "") ? row.unm = "S" : row.unm = "I"
    elseif ismissing(row.unm) && row.unm1 == row.unm2
      row.unm = "R"
    elseif row.unm1 != row.unm2
      levenshtein(row.unm1, row.unm2) > limiar_nome ? row.unm = "D0" : row.unm = "D"
    end      
  

    # checa diferença nas datas
    if ~ismissing(row.dn1) && ~ismissing(row.dn2)      
      if year(row.dn1) != year(row.dn2) && ~(row.abrev in ["RN1", "RN2"]) && (year(row.dn1) == year(row.dr1) || year(row.dn2) == year(row.dr2))
        if row.dn1 == row.dr1 || row.dn2 == row.dr2
          row.dt_flag = "DTigREG"
        elseif month(row.dn1) == month(row.dr1) || month(row.dn2) == month(row.dr2)
          row.dt_flag = "DTigREG1"
        else
          row.dt_flag = "DTigREG2"
        end
      end      
    end
  end

  #show(dfp)
  select!(dff, [:id, :pn, :un, :sn, :pnm, :unm, :dt_flag, :sexo1, :sexo2])

  leftjoin!(df, dff, on=:id)
  leftjoin!(df, dfp, on=:id)
  insertcols!(df, 2, :regra => "")  

  # validação da tabela de cruzamento
  # open("C://Users//rafa//Desktop//Teste//cruz_df.csv", "w") do io
  #   CSV.write(io, df, delim=";")
  # end  

  #show(sort(df, :escore_prob))
  println(Dates.format(convert(DateTime, now() - t_score), "MM:SS"))
  
  # algoritmo de avaliação
  for row in eachrow(df)
    list_freq = [row.pn, row.sn, row.un, row.pnm, row.unm]   
    #println(list_freq)
    if row.abrev in ["RN1", "RN2"] # regra para rn
      if ismissing(row.distdn) || ismissing(row.levnm)
        if ~ismissing(row.distdn) && (row.difday < 10 || row.distdn == 100) && ismissing(row.levnm) && row.levn > 90
          row.sexo1 != row.sexo2 ? row.regra = "Ncr4" : row.regra = "CR4"          
        end
      elseif row.levnm < 83 && (ismissing(row.distdn) || row.distdn < 70)
        row.regra = "SR2"        
      elseif row.levnm < 83 && row.pnm == "D"
        row.regra = "SR3"
      elseif row.distdn > 300 
        row.regra = "SR4"
      elseif row.levnm < 70 || ((row.levnm + row.distdn) < 158 && row.pnm in ["D", "2"] && row.unm in ["D", "2"])
        row.regra = "SR5"
      elseif row.sexo1 != row.sexo2 && (ismissing(row.distdn) || row.distdn < 90)
        row.regra = "SR6"
      elseif ~ismissing(row.distdn) && row.distdn > 90 && row.levnm > 93 
        row.sexo1 != row.sexo2 ? row.regra = "Ncr1" : row.regra = "CR1"
      elseif ~ismissing(row.distdn) && row.distdn > 90 && row.levnm > 95 
        row.sexo1 != row.sexo2 ? row.regra = "Ncr2" : row.regra = "CR2"
      elseif ~ismissing(row.distdn) && row.abrev == "RN2" && row.distdn == 100 && df.escore > 285 
        row.sexo1 != row.sexo2 ? row.regra = "Ncr3" :  row.regra = "CR3"
      else
          row.regra = "N"
      end
  

    elseif ~ismissing(row.distdn) && row.distdn < 60 && row.un in ["D", "2"] && row.pn in ["D", "2"] && row.sn in ["D", "S", "I", "2"] && row.pnm != "R"  # descrita no artigo
      if ~ismissing(row.levnm) && row.levn == 100 && row.levnm == 100 && (ismissing(row.distdn) || row.distdn > 40)
          row.regra = "NS1"
      else
          row.regra = "S1"
      end

    elseif ~ismissing(row.distdn) && (row.levn + row.distdn) < 140 && (ismissing(row.levnm) || ((row.levn + row.levnm) < 170 && (row.distdn + row.levnm) < 190)) && row.pn != "0" && row.pn != "R" 
      row.regra = "S2"

    elseif ~ismissing(row.distdn) && row.abrev in ["dif", "dif2"] && (row.levn + row.distdn) < 189 && row.pn != "0" && row.pn != "R" && (ismissing(row.levnm) || (row.levn + row.levnm) != 200) && row.un != "0"
      if row.escore_prob > 15 && count(i->(i == "2" || i == "D"), list_freq) < 4 
          row.regra = "Ns3"
      else
          row.regra = "S3"
      end

    elseif row.abrev == "AbrevX" && ~ismissing(row.levnm) && ~ismissing(row.distdn) && ((soma_string(list_freq[2:5]) > 3 && row.escore < 260) || row.escore < 210 || (soma_string(list_freq[2:5]) < 3 && row.escore < 235)) && (row.levn + row.distdn) < 193 
      if row.pn == "D0" && row.escore > 250 
          row.regra = "Ns4"
      else
          row.regra = "S4"
      end

    elseif row.abrev == "AbrevZ" && (ismissing(row.levnm) || row.levnm < 95) && (row.escore < 241 || (row.sn == "D" && (ismissing(row.distdn) || row.distdn != 100) && levsn(row.nome1, row.nome2) < 20 )) #CORRIGIR
      row.regra = "S5"

    elseif row.abrev == "Igual" && (row.escore < 204 || (row.sexo1 != row.sexo2 && row.escore < 220)) && (ismissing(row.levnm) || (row.levnm + row.levn) < 193) && count(i->(i == "2"), list_freq[1:4]) != 0 
      if ~ismissing(row.levnm) && row.levn > 93 && row.levnm > 91 && row.sexo1 == row.sexo2 && count(i->(i == "2" || i == "D" ), list_freq[2:5]) < 3 
          row.regra = "Ns6"
      else
          row.regra = "S6"
      end

    elseif row.abrev == "Igual" && (ismissing(row.distdn) || row.distdn < 60) && (row.pn == "2" || row.un == "2") && (row.sn in  ["S", "D", "1", "2"] || (row.sn == "I" && ~ismissing(row.distdn) && row.distdn < 40)) &&
      (((ismissing(row.levnm) || (row.levnm + row.levn) < 190) && soma_string(list_freq[1:3]) > 4) || (soma_string(list_freq[1:2]) > 2) || (soma_string(list_freq[1:2]) > 1 && (row.pn == "D" || row.un == "D"))) 
      
      if ~ismissing(row.levnm) && ((row.levn + row.levnm) > 195 && ~ismissing(row.distdn) && row.distdn > 40) || (row.dt_flag in ["DTigREG", "DTigREG1"] && (row.levn + row.levnm) > 191 && row.levn > 94) 
          row.regra = "Ns7"
      else
          row.regra = "S7"
      end

    elseif row.escore < 250 && ((row.escore_prob < 6 && row.sn == "I") || (row.escore_prob < 7 && row.sn == "S")) 
      row.regra = "S8"

    elseif row.pn == "D" && row.escore < 243 && (soma_string(list_freq) > 4 || count(i->(i == "D" || i == "D0"), list_freq[1:4]) > 3) 
      row.regra = "S9"

    elseif row.pn in ["2", "D"] && count(i->(i == "D"), list_freq[2:5]) >= 1 && soma_string(list_freq[2:5]) > 2 && (ismissing(row.distdn) || row.distdn < 93) && row.levn < 94 # corrgido
      row.regra = "S10"

    elseif ((ismissing(row.distdn) && row.levn < 85) || (~ismissing(row.distdn) && (row.levn + row.distdn) < 105)) && soma_string(list_freq) > 2 
      row.regra = "S11"

    elseif row.escore < 250 && (ismissing(row.distdn) || row.distdn < 51) && soma_string(list_freq) > 7 && (ismissing(row.levnm) || (row.levn + row.levnm) < 195) 
      row.regra = "S12"

    elseif row.abrev == "Igual" && row.escore < 230 && row.escore_prob < 17 && row.pnm == "D" && (row.escore_prob < 7 || count(i->(i == "2"), list_freq[1:3]) > 1) 
      row.regra = "S13"

    elseif row.pn in ["D", "2"] && row.un in ["D", "2"] && ((row.abrev != "Igual" && row.escore < 240 && row.escore_prob < 14) || (row.escore < 220 && row.escore_prob < 5)) 
      row.regra = "S14"

    elseif row.abrev == "AbrevX" && (row.escore_prob < 7 || (row.escore_prob < 14 && ismissing(row.distdn))) && (row.pn == "D" || row.sn == "D") 
      row.regra = "S15"

    elseif row.abrev == "dif1" && (ismissing(row.distdn) || row.distdn < 65) && (ismissing(row.levnm) || (row.levn + row.levnm) < 193)
      row.regra = "S16"

    elseif row.abrev == "Simples" && (ismissing(row.distdn) || row.distdn < 65)
      row.regra = "S19"
     
    elseif row.escore > 281 
      if row.pn == "D" 
          row.regra = "Nc1a"
      elseif row.pn == "D0" && row.sexo1 != row.sexo2 
          row.regra = "Nc1b"
      elseif row.pnm == "D" && soma_string(list_freq) > 5 && (ismissing(row.distdn) || row.distdn < 100)
          row.regra = "Nc1c"
      else
          row.regra = "C1"
      end

    elseif row.pn != "D" && row.escore > 247
      if row.pn == "D0" && row.sexo1 != row.sexo2 
          row.regra = "Nc2a"
      elseif (ismissing(row.distdn) || row.distdn < 80) && count(i->(i == "2"), list_freq[2:5]) > 2 && (row.escore_prob < 29 && count(i->(i == "2"), list_freq[2:5]) < 4) 
          row.regra = "Nc2b"
      elseif row.escore_prob < 14 && (ismissing(row.distdn) || row.distdn != 100) 
          row.regra = "Nc2c"
      elseif (count(i->(i == "2"), list_freq) + count(i->(i == "D"), list_freq[2:5])) > 3 && count(i->(i == "R"), list_freq) == 0 
          if row.pn != "D0" && row.levn > 94 && (row.escore > 30 || row.abrev == "Igual") && ~ismissing(row.distdn) && row.distdn == 100 
              row.regra = "C2b"
          else
              row.regra = "Nc2d"
          end
      elseif count(i->(i == "0" || i == "R"), list_freq) == 0 && (ismissing(row.distdn) || row.distdn < 70)
          row.regra = "Nc2e"
      else
          row.regra = "C2"
      end

    elseif row.pn == "R" && row.escore > 225 
      if count(i->(i == "R"), list_freq[2:5]) > 2 
          row.regra = "Nc3a"
      elseif row.escore > 235 && (ismissing(row.distdn) || row.distdn < 49) && row.un == "2" && row.pnm == "2" # corrigido
          row.regra = "Nc3b"
      elseif row.escore_prob < 14 
          row.regra = "Nc3c"
      else
          row.regra = "C3"
      end

    elseif row.escore > 235 && ~ismissing(row.distdn) && row.distdn > 83 && row.levn > 78 && first(row.pn, 1) != "D" && row.abrev == "Igual" # corrigido
      if (count(i->(i == "2"), list_freq) + count(i->(i == "D"), list_freq[2:5])) > 3 && count(i->(i == "R"), list_freq) == 0 
        if row.abrev == "Igual" && row.levn > 95 && ~ismissing(row.distdn) && row.distdn == 100 # corrigido
            row.regra = "C4b"
        else
            row.regra = "Nc4a"
        end
      else
          row.regra = "C4"
      end

    elseif ~ismissing(row.distdn) && row.distdn > 92 && row.levn > 95 && soma_string(list_freq[1:3]) < 4 && row.escore_prob > 4 
      row.regra = "C5"

    elseif row.pn in ["R", "0"] && row.escore > 230 && (row.pnm != "D" || row.unm != "D" || ismissing(row.levnm) || row.un != "2" || row.sn != "2") 
      if count(i->(i == "2" || i == "D"), list_freq[2:5]) > 3 
          row.regra = "Nc6a"
      elseif row.escore_prob < 15 && ((ismissing(row.levnm) || (row.levn + row.levnm) < 193) && ~ismissing(row.distdn)) 
          row.regra = "Nc6b"
      elseif count(i->(i == "2" || i == "D"), list_freq[2:5]) > 2 && ismissing(row.distdn)
          row.regra = "Nc6c"
      else
          row.regra = "C6"
      end

    elseif row.pn != "D" && row.levn > 94 && row.abrev == "Igual" && ~ismissing(row.distdn) && ~ismissing(row.distdn) && row.distdn == 100
      if row.sexo1 != row.sexo2 
          row.regra = "Nc7"
      else
          row.regra = "C7"
      end

    elseif ~ismissing(row.levnm) && row.levn > 94 && row.levnm > 93 && row.dt_flag in ["DTigREG", "DTigREG1"]
      if row.sexo1 != row.sexo2 
          row.regra = "Nc8"
      else
          row.regra = "C8"
      end

          # Um última onda de regras negativas para reduzir o número de pares destinados a revisão manual
    elseif row.sexo1 != row.sexo2 && row.levn < 95 
      row.regra = "S17a"

    elseif row.pnm in ["S", "I"] && row.escore_prob < 13
      row.regra = "S17b"

    elseif row.escore_prob < 2 || (row.escore_prob < 12 && (ismissing(row.levnm) || (row.levnm + row.levn) < 170) && ismissing(row.distdn) || (row.escore_prob < 10 && row.abrev == "Igual" && (ismissing(row.distdn) || row.distdn < 75)) || (row.escore_prob < 12 && (ismissing(row.distdn) || row.distdn < 30))) 
      row.regra = "S18"

    else
      row.regra = "N"      
    end
  end
  
  # validação das regras
  # open("C://Users//rafa//Desktop//Teste//cruz.csv", "w") do io
  #   CSV.write(io, df, delim=";")
  # end  

  filter!([:regra] => x -> x != "" && first(x, 1) != "S", df)
  insertcols!(df, 2, :par_rev => "-")

  unique!(df)
  df.id = axes(df, 1) 

  # carrega todos os dados
  DBInterface.execute(db, "DELETE FROM list_cruz")
  SQLite.load!(df, db, "list_cruz")

  # carrega o que vai ser revisado
  dfr = DataFrames.select(df, [:id, :regra, :par_rev])
  DataFrames.rename!(dfr, Dict([:id => :list_id])) 
  filter!([:regra] => x -> contains(x, "N"), dfr) # filtra só as linhas que devem ser revisadas
  insertcols!(dfr, 1, :id => axes(dfr,1))

  DBInterface.execute(db, "DELETE FROM list_cruz_rv")
  SQLite.load!(dfr, db, "list_cruz_rv")
        
  if size(dfr, 1) > 0 
    resp["modo_rev"] = true 
    revisado = 0
  else
    resp["modo_rev"] = false  
    revisado = 1
  end

  rel_n = string(size(df, 1))
  resp["textrel"] = set_st_import_bd(rel_n; tipo="rel")  
  resp["revisado"] = revisado
  resp["row_rev"] = 1
  resp["max_rev"] = size(dfr, 1)
  resp["cor"] = "positive"
  resp["msg"] = "Cruzamento concluído com sucesso" 

  # grava os dados do banco
  sql = """
  UPDATE st_cruz as tb
  SET modo_rev = $(resp["modo_rev"]), max_rev = $(resp["max_rev"]), linkado = 1, revisado=$revisado, rel_n= '$rel_n'
  WHERE tb.id = 1; """
  #println(sql)
  DBInterface.execute(db, sql)   

  return Json.json(resp)  
 
end

"Baixa os dados da base de dados"
function checa_nomes(vt::Vector, bd::String)
  dft = map(x -> string(x), unique(vt))
  loc = join(dft, "','") 

  bd == "b1" ? b = "1" : b = "2"

  sql = """
    select
      "index" as id$b,
      pn as pn$b,
      un as un$b,
      sn as sn$b,
      pnm as pnm$b,
      unm as unm$b,
      ibge as ibge$b,
      sexo as sexo$b,
      dr as dr$b

    from $(bd)_proc as tb
    where
      "index" in ('$loc')
  """
  df = DBInterface.execute(db, sql) |> DataFrame

  if bd == "b1"
    leftjoin!(df, freq_pn, on=:pn1=>:id)
    leftjoin!(df, freq_pnm, on=:pnm1=>:id)
    leftjoin!(df, freq_sn, on=:sn1=>:id)
    leftjoin!(df, freq_un, on=:un1=>:id)
    leftjoin!(df, freq_unm, on=:unm1=>:id)
  end

  return df

end

# Revisão
function revisa_row(row)
  sql = """
    select
      tb.nome1, tb.nome2, tb.nm_m1, tb.nm_m2, tb.dn1, tb.dn2, tb.escore, tb.escore_prob, tb.sexo1, tb.sexo2, tb.dt_flag, tb.pn, tb.un, tb.sn, tb.pnm, tb.unm, tb0.par_rev, tb.distdn, tb.dt_flag,
      b1_proc.cod as cod1, b1_proc.dr as dr1, b1_proc.ibge as ibge1, b1_proc.end as end1, 
      b2_proc.cod as cod2, b2_proc.dr as dr2, b2_proc.ibge as ibge2, b2_proc.end as end2 
    from list_cruz_rv tb0
      left join list_cruz tb on tb.id = tb0.list_id
      inner join b1_proc on b1_proc."index" = tb.id1
      inner join b2_proc on b2_proc."index" = tb.id2
    where tb0.id = $row;
  """
  df = DBInterface.execute(db, sql) |> DataFrame

  #print(df)

  df = df[1, :]
  return Dict(names(df) .=> values(df))
end

"Define se os registros são pares"
function revisa_row_par(row::Int64, par::String)
  sql = """
    UPDATE list_cruz_rv
    SET par_rev = '$par'
    WHERE id = $row;
  """
  println(sql)
  DBInterface.execute(db, sql) 

end
function revisa_row_par(row::String, par::String)
  @warn parse(Int64, row)
  revisa_row_par(parse(Int64, row), par)
end


# Relatórios
"Constrói o df com o relatório"
function gerar_relatorio(db, rel_id, b1_id, b2_id, nome_cruz)
  dict = Dict{String, Any}()
  println(rel_id)

  sql = """
    select
      tb.ordem,
      bd.col,
      tb.banco_id,
      tb.var_rel

    from rel_cols tb
      left join banco_cols as bd on bd.id = tb.var_org_id

    where tb.cruz_rel_id = $(rel_id)

    order by tb.ordem
  """
  df_cols = DBInterface.execute(db, sql) |> DataFrame

  show(df_cols)

  sql = """
    select
      id1, id2
    from list_cruz as list
      left join list_cruz_rv as rv on rv.list_id = list.id
    where
      not rv.par_rev is 'N'
    """
  rel = DBInterface.execute(db, sql) |> DataFrame

  # println(size(rel, 1))
  # show(rel)


  df1 = carregar_csv("b1")  
  dict["df_b1"] = df1
  show(df1)
  # println(bd)
  # println("Foi")

  cols = ["index"] ; append!(cols, filter([:banco_id] => x -> x == b1_id, df_cols).col)
  print(cols)
  leftjoin!(rel, DataFrames.select(df1, cols), on= :id1 => :index)
  show(rel)
  subs = Dict{String,String}()
  for row in eachrow(filter([:banco_id] => x -> x == b1_id, df_cols))
    row.col != row.var_rel && (subs[row.col] = row.var_rel)
  end
  println(subs)
  DataFrames.rename!(rel, subs)
  show(rel)

  print("foi")

  df1 = carregar_csv("b2")
  dict["df_b2"] = df1
  show(df1)
  # println(b2_id)
  # show(df_cols)
  cols = ["index"] ; append!(cols, filter([:banco_id] => x -> x == b2_id, df_cols).col)
  # println(cols)
  leftjoin!(rel, DataFrames.select(df1, cols), on= :id2 => :index)
  subs = Dict{String,String}()
  # show(rel)
  for row in eachrow(filter([:banco_id] => x -> x == b2_id, df_cols))
    subs[row.col] = row.var_rel
  end

  rename!(rel, subs)
  unique!(rel)

  # show(DataFrames.select(rel,df_cols.var_rel))
  Local = joinpath("data","reports", nome_cruz)

  if isdir(Local) == false
    try
      mkpath(Local)
      @warn "O diretório foi criado"
    catch
      @warn "Não possível criar o caminho"
    end
  end

  local escrita = false

  # println(df_cols.var_rel)  
  df_pos = get_sql_rel_pos(db, rel_id)

  # show(dict["df_b1"])
  show(describe(rel), allrows=true)

  escrita_a = true
  if size(df_pos, 1) > 0
    for row in eachrow(df_pos)
      println(row.function)
      escrita_0 = getfield(relatorio, Symbol(row.function))(rel, Local, dict)
      escrita_a == false && (escrita_a = escrita_0)
    end
  end

  
  select!(rel, df_cols.var_rel)

  try
    XLSX.writetable(joinpath(Local, "relatório bruto.xlsx"), rel, overwrite=true, sheetname="Relatório Bruto", anchor_cell="A1")
    escrita = true
  catch
    escrita = false
  end
 
  return escrita, escrita_a

end

"Relatório que encontra os registros que não foram notificados dos três exames"
function rel_avan_dc_n_notif(rel_avan, cruz)
  
  Local = joinpath("data","reports", cruz[:nome],"relatório.xlsx")

  df1 = carregar_csv("b1")

  df2 = XLSX.readtable(Local, 1) |> DataFrame
  
  filter!(["Status Exame", "Resultado"] => (x,y) -> x == "Resultado Liberado" && y == "Detectável", df1)

  df1 = antijoin(df1, df2, on="Requisição")

  select!(df1, ["Requisição", "Data da Coleta", "IBGE Município de Residência", "Paciente", "Exame", "Resultado"])

  Local = joinpath("data","reports", cruz[:nome],"relatório n notif.xlsx")

  XLSX.writetable(Local, overwrite=true, df1)

end

"Algorigmo que encontra os registros que não foram encerrados para os três exames"
function rel_avan_falta_encer(DiasPCR, DiasIgM, ClassfP, ClassfN, rel_avan, cruz, agravo)
  
  Local = joinpath("data","reports", cruz[:nome],"relatório.xlsx")

  df1 = XLSX.readtable(Local, 1) |> DataFrame

  filter!(["Dif Dias 1ºS", "Critério"] => (x,y) -> -6 < x < 91 && (ismissing(y) || y != 1), df1)
  show(names(df1))
  
  select!(df1, ["Notificação", "Dt_Not", "Nome", "Requisição", "Exame", "Dt_Coleta", "Resultado", "Classificação", "Critério", "Dif Dias 1ºS", "Dif Dias Not"])
  insertcols!(df1, 1, :check => false)

  for row in eachrow(df1)
    if row["Dif Dias 1ºS"] < DiasPCR && contains(row["Exame"], "PCR")
      if row["Resultado"] == "Detectável"
        row.check = true
        row["Classificação"] = ClassfP
        row["Critério"] = 1
      elseif row["Resultado"] == "Não Detectável" && (ismissing(row["Classificação"]) ||  (row["Classificação"] != 11 && row["Classificação"] != 12))
        row.check = true
        row["Classificação"] = ClassfN
        row["Critério"] = 1
      end     
    elseif contains(row["Exame"], "IgM") && ( row["Dif Dias 1ºS"] > DiasIgM || row["Resultado"] == "Reagente" )
      if row["Resultado"] == "Reagente"
        row.check = true
        row["Classificação"] = ClassfP
        row["Critério"] = 1
      elseif row["Resultado"] == "Não Reagente" && (ismissing(row["Classificação"]) ||  (row["Classificação"] != 11 && row["Classificação"] != 12))
        row.check = true
        row["Classificação"] = ClassfN
        row["Critério"] = 1
      end
    elseif contains(row["Exame"], "NS1") && ( row["Dif Dias 1ºS"] < 15 || row["Resultado"] == "Reagente" )
      if row["Resultado"] == "Reagente"
        row.check = true
        row["Classificação"] = ClassfP
        row["Critério"] = 1
      elseif row["Resultado"] == "Não Reagente" && (ismissing(row["Classificação"]) ||  (row["Classificação"] != 11 && row["Classificação"] != 12))
        row.check = true
        row["Classificação"] = ClassfN
        row["Critério"] = 1
      end
    
    end
  end

  filter!([:check] => x -> x == true, df1)

  select!(df1, Not([:check]))
  
  Local = joinpath("data","reports", cruz[:nome],"relatório encer $agravo.xlsx")

  XLSX.writetable(Local, overwrite=true, df1)
  
end

"Relatório que filtra os casos que faltam encerrar para dengue"
function rel_avan_falta_encer_d(rel_avan, cruz)
  DiasPCR = 7
  DiasIgM = 3
  ClassfP = 10
  ClassfN = 5

  agravo = "dengue"

  rel_avan_falta_encer(DiasPCR, DiasIgM, ClassfP, ClassfN, rel_avan, cruz, agravo)
  
end

"Relatório que filtra os casos que faltam encerrar para chikungunya"
function rel_avan_falta_encer_c(rel_avan, cruz)
  DiasPCR = 10
  DiasIgM = 4
  ClassfP = 13
  ClassfN = 5

  agravo = "chikungunya"

  rel_avan_falta_encer(DiasPCR, DiasIgM, ClassfP, ClassfN, rel_avan, cruz, agravo)
  
end

"Relatório que filtra os casos que faltam encerrar para zika"
function rel_avan_falta_encer_z(rel_avan, cruz)
  DiasPCR = 7
  DiasIgM = 3
  ClassfP = 10
  ClassfN = 5

  agravo = "zika"

  rel_avan_falta_encer(DiasPCR, DiasIgM, ClassfP, ClassfN, rel_avan, cruz, agravo)
  
end

@compile_workload begin
  # init_from_storage(Importar, debounce = 30) |> Pag_ini.handlers
  df = DataFrame(x=[1,2])
 
end

end # fim do modulo
