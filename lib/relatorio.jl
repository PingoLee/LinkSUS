module relatorio

include("importadores.jl")
include("linkage_f.jl")
using .linkage_f, .importadores

using DataFrames, CSV, DBFTables, XLSX, SQLite
using StringEncodings, Dates

# Funções de carregamento
export carregar_csv
function carregar_csv(bd::String)
  file = joinpath("data", "linksus", "importado", bd * ".csv")
  return DataFrame(CSV.File(open(read, file)))
end

export gerar_relatorio

"Gera o realtório avançado do covid"
function Real_Avan_Covid(df_o, df_b1, Local)
  # carrega mota realtório de positivas
  println("Foi pra outra função")
  
  # show(df_o)

  df = filter([:Municipio2, :Resultado] => (x, y) -> ~ismissing(x) && x == 172100 && ~ismissing(y) && y == "Detectável", df_o)
  rel_p = DataFrames.select(df, :id1)

  string("Foi")

  insertcols!(rel_p, :n => "")
  insertcols!(rel_p, :criterio => "C.L.")
  insertcols!(rel_p, :status_esus_ve => "")

  rel_p.liberacao_exame = df[!, "DT_Resul"]
  rel_p.n_requisicao_gal = df[!, "GAL"]

  insertcols!(rel_p, :dt_boletim => today() + Day(1))

  rel_p.n_notificacao = df[!, "Notificação"]
  rel_p.nome = df[!, "PacienteGAL"]
  rel_p.idade_anos = df[!, "Idade"]

  rel_p.dn = df[!, "DN"]
  rel_p.sexo = df[!, "Sexo"]
  rel_p.cns_cpf = map((x, y) -> ~ismissing(x) ? x : y , df[!, "CNS2"], df[!, "CNS"])
  rel_p.comorb_fator_de_risco = map(x -> ismissing(x) ? "Não" : x , df[!, "Comorbidade"])
  rel_p.telefone = map((x, y) -> ~ismissing(x) ? x : y , df[!, "Telefone2"], df[!, "Telefone"])
  rel_p.endereco = df[!, "endereco"]
  rel_p.unid_notificadora = df[!, "Unid_Not"]

  insertcols!(rel_p, :laboratorio => "Lacen")
  insertcols!(rel_p, :metodologia => "RT-PCR")

  rel_p.resultado = df[!, "Resultado"]

  insertcols!(rel_p, :obs => "")
  insertcols!(rel_p, :mun_solicitante => "")

  rel_p0 = DataFrames.select(rel_p, Not(:id1))

  # show(rel_p)

  df = filter([:Municipio2, :Resultado] => (x, y) -> x == 172100 && y != "Detectável", df_o)
  rel_n = DataFrames.select(df, :id1)

  insertcols!(rel_n, :n => "")
  insertcols!(rel_n, :criterio => "C.L.")  
  rel_n.liberacao_exame = df[!, "DT_Resul"]
  rel_n.n_requisicao_gal = df[!, "GAL"]
  rel_n.n_notificacao = df[!, "Notificação"]  
  insertcols!(rel_n, :dt_boletim => today() + Day(1))  
  rel_n.nome = df[!, "PacienteGAL"]
  rel_n.dn = df[!, "DN"]
  insertcols!(rel_n, :laboratorio => "Lacen")
  insertcols!(rel_n, :metodologia => "RT-PCR")
  rel_n.resultado = df[!, "Resultado"]
  insertcols!(rel_n, :mun_solicitante => "")

  DataFrames.select!(rel_n, Not(:id1))

  # show(rel_n)
  rel_n0 = copy(rel_n)

  # procura os outros municípios  
  df = antijoin(df_b1, df_o, on=:Requisição => :GAL)
  filter!(["IBGE Município de Residência", "IBGE Município Solicitante", "COVID" ] => (x, y, z) -> (x == 172100 || y == 172100) && ~ismissing(z) && z == "Detectável" , df)
  unique!(df, :Requisição)
  rel_p = DataFrames.select(df, :Requisição)
  # show(df)
  
  insertcols!(rel_p, :n => "")
  insertcols!(rel_p, :criterio => "C.L.")
  insertcols!(rel_p, :status_esus_ve => "")

  rel_p.liberacao_exame = df[!, "Data da Liberação"]
  rel_p.n_requisicao_gal = df[!, "Requisição"]
  insertcols!(rel_p, :dt_boletim => today() + Day(1))
  insertcols!(rel_p, :n_notificacao => "SEM NOT")  
  rel_p.nome = df[!, "Paciente"]
  rel_p.idade_anos = map((x, y) -> x == "Ano(s)" ? y : 0 ,df[!,"Tipo Idade"], df[!, "Idade"])
  rel_p.dn = df[!, "Data de Nascimento"]
  rel_p.sexo = df[!, "Sexo"]
  rel_p.cns_cpf = df[!, "CNS"]
  insertcols!(rel_p, :comorb_fator_de_risco => "-")
  rel_p.telefone = df[!, "Telefone"]
  rel_p.endereco = map((x , y) -> string(x, " ", y), df[!, "Bairro"], df[!, "Endereço"])
  rel_p.unid_notificadora = map(x -> replace(x, "UNIDADE DE SAUDE DA FAMILIA" => "USF"), df[!, "Unidade Solicitante"])
  insertcols!(rel_p, :laboratorio => "Lacen")
  insertcols!(rel_p, :metodologia => "RT-PCR")
  rel_p.resultado = df[!, "COVID"]
  insertcols!(rel_p, :obs => "")
  rel_p.mun_solicitante = map((x, y) -> x == y ? "Solic. Palmas e mora Palmas" : y == 172100 ? "Solic. fora e mora Palmas" : "Solic. Palmas e mora fora" , df[!, "IBGE Município Solicitante"], df[!, "IBGE Município de Residência"])

  select!(rel_p, Not(:Requisição))
  append!(rel_p, rel_p0; promote=true)
  sort!(rel_p, :n_notificacao)
  show(rel_p)

  df = antijoin(df_b1, df_o, on=:Requisição => :GAL)
  filter!(["IBGE Município de Residência", "IBGE Município Solicitante", "COVID" ] => (x, y, z) -> (x == 172100 || y == 172100) && ~ismissing(z) && z != "Detectável" , df)
  unique!(df, :Requisição) 
  rel_n = DataFrames.select(df, :Requisição)

  insertcols!(rel_n, :n => "")
  insertcols!(rel_n, :criterio => "C.L.")  
  rel_n.liberacao_exame = df[!, "Data da Liberação"]
  rel_n.n_requisicao_gal = df[!, "Requisição"]
  insertcols!(rel_n, :n_notificacao => "SEM NOT")
  insertcols!(rel_n, :dt_boletim => today() + Day(1))  
  rel_n.nome = df[!, "Paciente"]
  rel_n.dn = df[!, "Data de Nascimento"]
  insertcols!(rel_n, :laboratorio => "Lacen")
  insertcols!(rel_n, :metodologia => "RT-PCR")
  rel_n.resultado = df[!, "COVID"]
  rel_n.mun_solicitante = map((x, y) -> x == y ? "Solic. Palmas e mora Palmas" : y == 172100 ? "Solic. fora e mora Palmas" : "Solic. Palmas e mora fora" , df[!, "IBGE Município Solicitante"], df[!, "IBGE Município de Residência"])
  
  select!(rel_n, Not(:Requisição))
  append!(rel_n, rel_n0)
  sort!(rel_n, :n_notificacao)
  
  rel_p.dn = convert(Vector{Union{Missing, Dates.Date}}, rel_p.dn)
  rel_p.sexo = convert(Vector{Union{Missing,String}}, rel_p.sexo)
  rel_p.resultado = convert(Vector{Union{Missing,String}}, rel_p.resultado)
  rel_n.resultado = convert(Vector{Union{Missing,String}}, rel_n.resultado)
  rel_n.dn = convert(Vector{Union{Missing, Dates.Date}}, rel_n.dn)

  # show(rel_n)
  # show(DataFrames.select(rel_p, Not([:n, :liberacao_exame, :nome, :comorb_fator_de_risco, :n_requisicao_gal, :unid_notificadora])))
  
  local escrita = false
  try    
    XLSX.writetable(joinpath(Local, "relatório boletim.xlsx"), overwrite=true, "Positivas" => rel_p, "Negativas" => rel_n)
    escrita = true        
  catch
    escrita = false
  end

  println(escrita)

  return escrita

end


"Constrói o df com o relatório"
function gerar_relatorio(rel_id, b1_id, b2_id, nome_cruz)  
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

  # show(df_cols)

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
  df_b1 = copy(df1)
  # show(df1)
  # println(bd)
  cols = ["index"] ; append!(cols, filter([:banco_id] => x -> x == bd[:b1_id], df_cols).col)
  # print(cols)
  leftjoin!(rel, DataFrames.select(df1, cols), on= :id1 => :index)
  subs = Dict{String,String}()
  for row in eachrow(filter([:banco_id] => x -> x == bd[:b1_id], df_cols))
    row.col != row.var_rel && (subs[row.col] = row.var_rel)
  end
  # println(subs)
  DataFrames.rename!(rel, subs)
  # show(rel)

  # print("foi")

  df1 = carregar_csv("b2")  
  # show(df1)
  cols = ["index"] ; append!(cols, filter([:banco_id] => x -> x == bd[:b2_id], df_cols).col)
  # println(cols)
  leftjoin!(rel, DataFrames.select(df1, cols), on= :id2 => :index)
  subs = Dict{String,String}()
  # show(rel)
  for row in eachrow(filter([:banco_id] => x -> x == bd[:b2_id], df_cols))
    subs[row.col] = row.var_rel
  end
  rename!(rel, subs)
  
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
  
  try       
    XLSX.writetable(joinpath(Local, "relatório.xlsx"), rel, overwrite=true, sheetname="Relatório Bruto", anchor_cell="A1")
    escrita = true  
  catch   
    escrita = false
  end
  print(escrita)
    
  escrita_a = Real_Avan_Covid(rel, df_b1, Local)

  return escrita, escrita_a

end


# RELATÓRIOS AVANÇADOS
export rel_nsus_covid_pos




end # fim do modulo