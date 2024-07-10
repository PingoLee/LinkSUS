module relatorio

# include("importadores.jl")
# include("linkage_f.jl")
using LinkSUS.linkage_f
using LinkSUS.importadores

using DataFrames, CSV, DBFTables, XLSX, SQLite
using StringEncodings, Dates

# # Funções de carregamento
# export carregar_csv
# function carregar_csv(bd::String)
#   file = joinpath("data", "linksus", "importado", bd * ".csv")
#   return DataFrame(CSV.File(open(read, file)))
# end

export Real_Avan_Covid, rlt_gal_arbo

"Gera o realtório avançado do covid"
function Real_Avan_Covid(df_o, Local, dict::Dict{String, Any})
  # carrega mota realtório de positivas  
  println("Foi pra outra função")

  df_b1 = dict["df_b1"]

  show(describe(dict[df_o]), allrows=true)

  # df_o.Resultado = convert(Vector{Union{Missing,String, Nothing}}, df_o.Resultado)
  # show(DataFrames.select(df_o, [:Municipio2, :Resultado]))
  df = filter([:Municipio2, :Resultado] => (x, y) -> ~ismissing(x) && x == 172100 && ~ismissing(y) && y == "Detectável", df_o)

  show(df)
  
  rel_p = DataFrames.select(df, :id1)

  # println("Foi")

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

  show(rel_p)

  df = filter([:Municipio2, :Resultado] => (x, y) -> ~ismissing(x) && x == 172100 && ~ismissing(y) && y == "Detectável", df_o)
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

  show(rel_n)
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
  rel_p.endereco = map((x , y) -> string(ismissing(x) ? "" : x, " ", y), df[!, "Bairro"], df[!, "Endereço"])
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

"Gera o relatório de arboviroses"
function rlt_gal_arbo(df_o, Local, dict::Dict{String, Any})
  # println(Local)
  insertcols!(df_o, :"Dif Dias 1ºS" => 0)
  insertcols!(df_o, :"Dif Dias Not" => 0)

  #   show(df_o)
  df_o.Exame = convert(Vector{Union{Missing, String}}, df_o.Exame)

  for row in eachrow(df_o)
    row["Dif Dias 1ºS"] = Dates.value(row["Dt_Coleta"]) - Dates.value(row["Dt 1ºSint"])
    row["Dif Dias Not"] = Dates.value(row["Dt_Coleta"]) - Dates.value(row["Dt_Not"])

    if contains(row["Exame"], "Dengue Teste R")        
      row["Exame"] = "Exame Sorológico (IgM) DengueR"
    elseif row["Exame"] == "Dengue, IgM"
      row["Exame"] = "Exame Sorológico (IgM) Dengue"
    elseif row["Exame"] == "Dengue, Biologia Molecular"
      row["Exame"] = "Dengue, RT-PCR"
    elseif row["Exame"] == "Dengue, NS1"
      row["Exame"] = "NS1"
    elseif contains(row["Exame"], "Chikungunya, Teste R*")
      row["Exame"] = "Exame Sorológico (IgM) ChikungunyaR"
    elseif row["Exame"] == "Chikungunya, IgM"
      row["Exame"] = "Exame Sorológico (IgM) Chikungunya"
    elseif row["Exame"] == "Chikungunya, Biologia Molecular"
      row["Exame"] = "Chikungunya, RT-PCR"
    elseif row["Exame"] == "Zika, IgM"
      row["Exame"] = "Exame Sorológico (IgM) Zika"
    elseif row["Exame"] == "Zika, Biologia Molecular"
        row["Exame"] = "Zika, RT-PCR"
    elseif contains(row["Exame"], "Teste R") && contains(row["Exame"], "Zika")
      row["Exame"] = "Exame Sorológico (IgM) ZikaR"
    end


  end

  local escrita = false
  try
    XLSX.writetable(joinpath(Local, "relatório.xlsx"), overwrite=true, df_o)
    escrita = true
  catch
    escrita = false
  end


  return escrita
  
end



# RELATÓRIOS não relacionados ao cruzamento de dados
export rel_nsus_covid_pos

"relatório de casos positivos de covid-19 que não foram laçados da planilha do coe"
function rel_nsus_covid_pos(dfCOE::DataFrame, nome_cruz::String)  
  dfCom = DataFrame(CSV.File(open(read, joinpath("data" , "linksus", "parameters", "nsus", "Comorbidades.csv"), enc"windows-1252"), delim=";"))

  Colunas = ["LIBERAÇÃO EXAME", "Nº REQUISIÇÃO GAL", "Nº NOTIFICAÇÃO", "NOME", "CNS/CPF", "DN", "UNIDADE NOTIFICADORA", "METODOLOGIA"]

  if issubset(Colunas, names(dfCOE)) == false
      return true, "A planilha do COE teve o títulos das colunas modificados"
  end


  dfCOE = DataFrames.select(dfCOE, ["LIBERAÇÃO EXAME", "Nº REQUISIÇÃO GAL", "Nº NOTIFICAÇÃO", "NOME", "CNS/CPF", "DN", "UNIDADE NOTIFICADORA", "METODOLOGIA"])
  dfCOE."Nº NOTIFICAÇÃO" = map(x -> ismissing(x) ? missing : strip(string(x)), dfCOE."Nº NOTIFICAÇÃO")
  #dfCOE = filter("Nº NOTIFICAÇÃO" => x -> ismissing(x) ? false : contains(x, "-2021"), dfCOE)

  # Coloca o metaphone
  col = ncol(dfCOE)
  insertcols!(dfCOE, col + 1, "metaphone" => "")

  for i = 1: nrow(dfCOE)
      if ismissing(dfCOE[i, :DN]) == false && (isa(dfCOE[i, :DN], DateTime) || isa(dfCOE[i, :DN], Date))  && ismissing(dfCOE[i, "NOME"]) == false
          dfCOE[i, :metaphone] = string(metaphone_br(dfCOE[i, "NOME"], Tamanho=20), Dates.format(dfCOE[i, :DN], "yyyy-mm-dd"))
      end
  end

  # importa notifica
  dfNOT = get_csv_gal(joinpath("data", "linksus", "bruto", "file2_id.csv"))

  select!(dfNOT, ["num_notificacao", "nome_unidade", "data_notificacao", "cartao_sus", "cpf", "nome_paciente", "idade_anos_dt_notific",
                  "data_nascimento", "sexo", "municipio_paciente", "bairro", "logradouro", "endereco_outra_cidade",
                  "quadra", "lote", "pais", "telefone", "telefone_2", "telefone_3", "comorb_pulm", "comorb_cardio", "comorb_renal",
                  "comorb_hepat", "comorb_diabe", "comorb_imun", "comorb_hiv", "comorb_neopl", "comorb_tabag",
                  "comorb_neuro_cronica", "comorb_neoplasias", "comorb_tuberculose", "comorb_obesidade", "comorb_cirurgia_bariat",
                  "amostra_t_rapido", "tipo_amostra_t_rapido", "dt_coleta_t_rapido", "resultado_t_rapido", "amostra_sorologia", "tipo_amostra_sorologia",
                  "dt_coleta_sorologia", "resultado_sorologia", "amostra_rt_pcr", "dt_coleta_rt_pcr", "resultado_rt_pcr", "class_final", "crit_conf", "dt_encerramento"])


  dfNOT = filter(["pais", "municipio_paciente"] => (x, y) -> ~ismissing(x) && contains(string(x), "NULL") && contains(string(y), "PALMAS - TO") , dfNOT)

  # filtra casos encerrados
  dfNOT = filter(["class_final", "crit_conf", "dt_encerramento"] => (x, y, z) ->
                  (ismissing(x) == false && x in [3, 4] && ismissing(y) == false && ismissing(z) == false) ? false : true , dfNOT)

  # Processar as informações



  LinC = nrow(dfCom)
  LinN = nrow(dfNOT)

  insertcols!(dfNOT, 1, :Comorbidade => "-")
  insertcols!(dfNOT, 1, :Metodo_exame => "-")
  insertcols!(dfNOT, 1, :Resultado => "-")
  insertcols!(dfNOT, 1, :Obs_Exame => "-")
  insertcols!(dfNOT, 1, :Endereço => "-")
  insertcols!(dfNOT, 1, :Telefone_fim => "-")
  insertcols!(dfNOT, 1, :Data_exame => "")
  dfNOT.Data_exame = convert(Vector{Union{Missing,String, Date}}, dfNOT.Data_exame)

  dfNOT.resultado_t_rapido = map(x -> ismissing(x) ? 0 : isa(x, Number) ? x : 0, dfNOT.resultado_t_rapido)
  dfNOT.resultado_rt_pcr = map(x -> ismissing(x) ? 0 : isa(x, Number) ? x : 0, dfNOT.resultado_rt_pcr)
  dfNOT.resultado_sorologia = map(x -> ismissing(x) ? 0 : isa(x, Number) ? x : 0, dfNOT.resultado_sorologia)
  dfNOT.dt_coleta_t_rapido = map(x -> ismissing(x) ? missing : isa(x, Date) ? x : contains(x,"-") ? Date(x, DateFormat("yyyy-mm-dd")) : Date(x, DateFormat("dd/mm/yyyy")), dfNOT.dt_coleta_t_rapido)
  dfNOT.dt_coleta_sorologia = map(x -> ismissing(x) ? missing : isa(x, Date) ? x : contains(x,"-") ? Date(x, DateFormat("yyyy-mm-dd")) : Date(x, DateFormat("dd/mm/yyyy")), dfNOT.dt_coleta_sorologia)
  dfNOT.dt_coleta_rt_pcr = map(x -> ismissing(x) ? missing : isa(x, Date) ? x : contains(x,"-") ? Date(x, DateFormat("yyyy-mm-dd")) : Date(x, DateFormat("dd/mm/yyyy")), dfNOT.dt_coleta_rt_pcr)
  dfNOT.data_notificacao = map(x -> ismissing(x) ? missing : isa(x, Date) ? x : contains(x,"-") ? Date(x, DateFormat("yyyy-mm-dd")) : Date(x, DateFormat("dd/mm/yyyy")), dfNOT.data_notificacao)
  dfNOT.data_nascimento = map(x -> ismissing(x) ? missing : isa(x, Date) ? x : contains(x,"-") ? Date(x, DateFormat("yyyy-mm-dd")) : Date(x, DateFormat("dd/mm/yyyy")), dfNOT.data_nascimento)

  for i = 1:LinN
      # consolida as comorbidades
      for j = 1:LinC
          if isa(dfNOT[i,dfCom[j,1]], Number) && dfNOT[i,dfCom[j,1]] == 1
              if dfNOT[i, :Comorbidade] == "-"
                  dfNOT[i, :Comorbidade] = dfCom[j,2]
              else
                  dfNOT[i, :Comorbidade] = join([string(dfNOT[i, :Comorbidade]), "| \n", dfCom[j,2]])
              end
          end
      end

      # Identificar o tipo de teste
      if dfNOT[i, "resultado_t_rapido"] == 1
          if dfNOT[i, "resultado_rt_pcr"] == 2
              dfNOT[i, "Obs_Exame"] =  "RT-PCR deu negativo"
          end
          if dfNOT[i, "tipo_amostra_t_rapido"] == 1
              dfNOT[i, "Resultado"] = "IgG POSITIVO"
          elseif dfNOT[i, "tipo_amostra_t_rapido"] == 2
              dfNOT[i, "Resultado"] = "IgM POSITIVO"
          elseif dfNOT[i, "tipo_amostra_t_rapido"] == 3
              dfNOT[i, "Resultado"] = "IgG/IgM POSITIVO"
          elseif dfNOT[i, "tipo_amostra_t_rapido"] == 4
              dfNOT[i, "Resultado"] = "AG POSITIVO"
          end
          dfNOT[i, "Metodo_exame"] = "Teste Rápido"
          if ismissing(dfNOT[i, "dt_coleta_t_rapido"]) == false
              if isa(dfNOT[i, :dt_coleta_t_rapido], Date)
                  dfNOT[i, "Data_exame"] = dfNOT[i, "dt_coleta_t_rapido"]
              else
                  dfNOT[i, "Data_exame"] = Dates.format(dfNOT[i, "dt_coleta_t_rapido"], "dd/mm/yyyy")
              end
          end
      elseif dfNOT[i, "resultado_sorologia"] == 1
          if dfNOT[i, "resultado_rt_pcr"] == 2
              dfNOT[i, "Obs_Exame"] =  "RT-PCR deu negativo"
          end
          dfNOT[i, "Metodo_exame"] = "Sorologia"
          if dfNOT[i, "tipo_amostra_sorologia"] == 1
              dfNOT[i, "Resultado"] = "IgA POSITIVO"
          elseif dfNOT[i, "tipo_amostra_sorologia"] == 2
              dfNOT[i, "Resultado"] = "IgG POSITIVO"
          elseif dfNOT[i, "tipo_amostra_sorologia"] == 3
              dfNOT[i, "Resultado"] = "IgM POSITIVO"
          elseif dfNOT[i, "tipo_amostra_sorologia"] == 4
              dfNOT[i, "Resultado"] = "IgG/IgM POSITIVO"
          end
          if ismissing(dfNOT[i, "dt_coleta_sorologia"]) == false
              if isa(dfNOT[i, :dt_coleta_sorologia], Date)
                  dfNOT[i, "Data_exame"] = dfNOT[i, "dt_coleta_sorologia"]
              else
                  dfNOT[i, "Data_exame"] = Dates.format(dfNOT[i, "dt_coleta_sorologia"], "dd/mm/yyyy")
              end
          end
      elseif dfNOT[i, "resultado_rt_pcr"] == 1
          dfNOT[i, "Metodo_exame"] = "RT-PCR"
          dfNOT[i, "Resultado"] = "DETECTÁVEL"
          if ismissing(dfNOT[i, "dt_coleta_rt_pcr"]) == false
              if isa(dfNOT[i, :dt_coleta_rt_pcr], Date)
                  dfNOT[i, "Data_exame"] = dfNOT[i, "dt_coleta_rt_pcr"]
              else
                  dfNOT[i, "Data_exame"] = Dates.format(dfNOT[i, "dt_coleta_rt_pcr"], "dd/mm/yyyy")
              end
          end
      else
          if dfNOT[i, "resultado_rt_pcr"] == 2
              dfNOT[i, "Metodo_exame"] = "RT-PCR"
              dfNOT[i, "Resultado"] = "NÃO DETECTÁVEL"
          elseif dfNOT[i, "resultado_sorologia"] == 2
              dfNOT[i, "Metodo_exame"] = "Sorologia"
              dfNOT[i, "Resultado"] = "NEGATIVO"
          elseif dfNOT[i, "resultado_t_rapido"] == 2
              dfNOT[i, "Metodo_exame"] = "Teste Rápido"
              dfNOT[i, "Resultado"] = "NEGATIVO"
          end
      end

      Testes = ["resultado_rt_pcr", "resultado_sorologia", "resultado_t_rapido"]
      N_testes = 0
      Checagem = 0
      Divergencia = "Não"
      for j in Testes
          if dfNOT[i, j] in [1,2]
              N_testes += 1
              if Checagem != 0
                  if  Checagem != dfNOT[i, j]
                      Divergencia = "Sim"
                  end
              else
                  Checagem = dfNOT[i, j]
              end
          end
      end

      if N_testes > 1
          if dfNOT[i, "Obs_Exame"] ==  "RT-PCR deu negativo"
          elseif Divergencia == "Não"
              dfNOT[i, "Obs_Exame"] =  "Mais de um teste informado"
          else
              dfNOT[i, "Obs_Exame"] =  "Mais de um teste informado, mas divergente"
          end
      end

      # Corrige endereço
      if (ismissing(dfNOT[i, "bairro"]) == false && contains(dfNOT[i, "bairro"],"Não Encontrado") == false) ||
          (ismissing(dfNOT[i, "logradouro"]) == false && contains(dfNOT[i, "logradouro"],"Não Encontrado")== false)
              if (ismissing(dfNOT[i, "bairro"]) == false && contains(dfNOT[i, "bairro"],"Não Encontrado")== false)
                  dfNOT[i, "Endereço"] = uppercase(dfNOT[i, "bairro"])
              end

              if (ismissing(dfNOT[i, "logradouro"]) == false && contains(dfNOT[i, "logradouro"],"Não Encontrado")== false)
                  if dfNOT[i, "Endereço"] == "-"
                      dfNOT[i, "Endereço"] = dfNOT[i, "logradouro"]
                  else
                      dfNOT[i, "Endereço"] = join([dfNOT[i, "Endereço"], " ", uppercase(dfNOT[i, "logradouro"])])
                  end
              end

              if (ismissing(dfNOT[i, "quadra"]) == false && contains(string(dfNOT[i, "quadra"]),"Não Encontrado")== false)
                  if dfNOT[i, "Endereço"] == "-"
                      dfNOT[i, "Endereço"] = string(dfNOT[i, "quadra"])
                  else
                      dfNOT[i, "Endereço"] = join([dfNOT[i, "Endereço"], " ", uppercase(string(dfNOT[i, "quadra"]))])
                  end
              end

              if (ismissing(dfNOT[i, "lote"]) == false && contains(string(dfNOT[i, "lote"]),"não sabe dizer")== false)
                  if dfNOT[i, "Endereço"] == "-"
                      dfNOT[i, "Endereço"] = dfNOT[i, "lote"]
                  else
                      dfNOT[i, "Endereço"] = join([dfNOT[i, "Endereço"], " Lote: ", uppercase(string(dfNOT[i, "lote"]))])
                  end
              end
      end


      if dfNOT[i, "Endereço"] == "-"
          if ismissing(dfNOT[i, "endereco_outra_cidade"]) == false
              dfNOT[i, "Endereço"] = uppercase(string(dfNOT[i, "endereco_outra_cidade"]))
          else
              dfNOT[i, "Endereço"] = "COLETAR NO INFORME"
          end
      elseif ismissing(dfNOT[i, "endereco_outra_cidade"]) == false
          dfNOT[i, "Endereço"] = join([dfNOT[i, "Endereço"], "; ", uppercase(string(dfNOT[i, "endereco_outra_cidade"]))])
      end

      if ismissing(dfNOT[i, "telefone"]) == false && dfNOT[i, "telefone"] != 0
          dfNOT[i, "Telefone_fim"] = string(dfNOT[i, "telefone"])
      end

      if ismissing(dfNOT[i, "telefone_2"]) == false && dfNOT[i, "telefone_2"] != 0
          if contains(string(dfNOT[i, "Telefone_fim"]), string(dfNOT[i, "telefone_2"])) == false
              dfNOT[i, "Telefone_fim"] = join([dfNOT[i, "Telefone_fim"], "| \n", string(dfNOT[i, "telefone_2"])])
          end
      end
      if ismissing(dfNOT[i, "telefone_3"]) == false && dfNOT[i, "telefone_3"] != 0
          if contains(string(dfNOT[i, "Telefone_fim"]), string(dfNOT[i, "telefone_3"])) == false
              dfNOT[i, "Telefone_fim"] = join([dfNOT[i, "Telefone_fim"], "| \n", string(dfNOT[i, "telefone_3"])])
          end
      end
      if ismissing(dfNOT[i, "cartao_sus"]) == false && dfNOT[i, "cartao_sus"] == 0
          dfNOT[i, "cartao_sus"] = dfNOT[i, "cpf"]
      end
      dfNOT[i, "sexo"] = SubString(dfNOT[i, "sexo"], 4, 4)
      if findfirst('(', dfNOT[i, "nome_unidade"]) != nothing
          dfNOT[i, "nome_unidade"] = SubString(dfNOT[i, "nome_unidade"], 1, findfirst('(', dfNOT[i, "nome_unidade"]) - 1)
      end
  end

  dfNOT = filter("Resultado" => x -> x != "-", dfNOT)



  # dfCOE."pais" = map(x -> ismissing(x) ? missing : string(x), dfCOE."pais")


  rename!(dfCOE, Dict("Nº NOTIFICAÇÃO" => "num_notificacao"))
  dfNOT = leftjoin(dfNOT, dfCOE,  on="num_notificacao", matchmissing=:equal)
  #dfNOT = filter(["Resultado", "NOME"]  => (x, y) -> x != "-" & ismissing(y), dfNOT)

  dfNOT = filter(["Resultado", "NOME"]  => (x, y) -> x != "NEGATIVO" && x != "NÃO DETECTÁVEL" && ismissing(y), dfNOT)

  insertcols!(dfNOT, 1, :N => "")
  insertcols!(dfNOT, 1, :Cirtério => "C.L")
  insertcols!(dfNOT, 1, "STATUS e-SUS VE" => "")

  insertcols!(dfNOT, 1, :GAL => "")
  insertcols!(dfNOT, 1, "DATA DO BOLETIM" => "")
  insertcols!(dfNOT, 1, "Laboratório" => "")

  select!(dfNOT, ["data_notificacao", "N", "Cirtério", "STATUS e-SUS VE", "Data_exame", "GAL", "DATA DO BOLETIM", "num_notificacao",
                  "nome_paciente", "idade_anos_dt_notific", "data_nascimento", "sexo", "cartao_sus", "Comorbidade",
                  "Telefone_fim", "Endereço", "nome_unidade", "Laboratório", "Metodo_exame", "Resultado", "Obs_Exame"])


  # Monta o código metaphone e grava
  col = ncol(dfNOT)
  insertcols!(dfNOT, col + 1, "metaphone" => "")

  for i = 1: nrow(dfNOT)
      if ismissing(dfNOT[i, :data_nascimento]) == false && (isa(dfNOT[i, :data_nascimento], DateTime) || isa(dfNOT[i, :data_nascimento], Date))
          dfNOT[i, :metaphone] = string(metaphone_br(dfNOT[i, :nome_paciente], Tamanho=20), Dates.format(dfNOT[i, :data_nascimento], "yyyy-mm-dd"))
      end
  end

  # Local = joinpath("data","reports", nome_cruz, "Notificações faltantes.xlsx")

  # df = copy(dfNOT)

  # for col in names(df)
  #     col2 = Symbol(col)
  #     df[!, col2] = map(x -> ismissing(x) ? missing : string(x), df[!, col2])
  # end

  # XLSX.writetable(Local, df, overwrite=true, sheetname="report", anchor_cell="A1")

  # monta a deduplicação
  #dfCOE[!, "LIBERAÇÃO EXAME"] = map(x -> ismissing(x) || (isa(x, DateTime) == false && isa(x, Date) == false)  ? missing : Dates.format(x, "dd/mm/yyyy"), dfCOE[!, "LIBERAÇÃO EXAME"])
  dfNOT = leftjoin(dfNOT, DataFrames.select(dfCOE, ["metaphone", "num_notificacao", "UNIDADE NOTIFICADORA", "LIBERAÇÃO EXAME", "METODOLOGIA"]) ,
                          on="metaphone", matchmissing=:equal, makeunique=true)

  data = Date(2021,08,01)

  dfNOT = filter(["data_notificacao", "Data_exame"]  => (x, y) -> x >= data || (ismissing(y) == false && isa(y, DateTime) && y >= data), dfNOT)

  Local = joinpath("data","reports", nome_cruz, "Notificações faltantes.xlsx")

  df = copy(dfNOT)

  df.data_notificacao = map(x -> ismissing(x) ? missing :  Dates.format(x, "dd/mm/yyyy"), df.data_notificacao)
  df.Data_exame = map(x -> ismissing(x) ? missing :  Dates.format(x, "dd/mm/yyyy"), df.Data_exame)
  df.data_nascimento = map(x -> ismissing(x) ? missing :  Dates.format(x, "dd/mm/yyyy"), df.data_nascimento)
  df[!, "LIBERAÇÃO EXAME"] = map(x -> ismissing(x) ? missing :  Dates.format(x, "dd/mm/yyyy"),  df[!, "LIBERAÇÃO EXAME"])

  for col in names(df)
      col2 = Symbol(col)
      df[!, col2] = map(x -> ismissing(x) ? missing : string(x), df[!, col2])
  end

  local gravado = false
  try
    XLSX.writetable(Local, df, overwrite=true, sheetname="report", anchor_cell="A1")
    gravado = true
  catch
    gravado = false
  end


  return gravado, "Processamento concluído"

end







end # fim do modulo