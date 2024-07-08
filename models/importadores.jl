module importadores

using DataFrames, CSV, DBFTables, XLSX
using StringEncodings, Dates
import LinkSUS.SearchLight: query

export get_csv_gal, get_dbf
# coleções de funções para importar arquivos
"""Importa os arquivos do gal"""
function get_csv_gal(file::String)::DataFrame
    return DataFrame(CSV.File(open(read, file, enc"windows-1252"), delim=";"))
end

"""Importa os arquivos em dbf"""
function get_dbf(file::String)::DataFrame
    return DataFrame(DBFTables.Table(file))
end
# importadores.get_dbf("C:\\Sistemas\\LinkSUS\\data\\linksus\\bruto\\file2_id.dbf")

# importa do sql
export get_sql_bancos_defs, get_sql_bancos_cols, get_sql_bancos_subs, get_sql_bancos_prep, get_sql_rel_pos

"""importa o dict dos bancos (b1 e b2)"""
function get_sql_bancos_defs(crz::String)
    df1 = query( 
        """select 
                tb.nome, bd.*
            from opc_cruzamento as tb 
                inner join bancos as bd on bd.id = tb.b1_id 

            where tb.id='$crz'""") 

    df2 = query( 
        """select 
                tb.nome, bd.*
            from opc_cruzamento as tb 
                inner join bancos as bd on bd.id = tb.b2_id 

            where tb.id='$crz'""") 

    insertcols!(df1, 1, :file => "file1_id")
    insertcols!(df2, 1, :file => "file2_id")

    return df1[1,:], df2[1,:]
end

"""Importa as definições para formatação e checagem das colunas dos bancos de dados"""
function get_sql_bancos_cols(banco_id::Int64)::DataFrame
    df1 = query(
        """select 
                *
            from banco_cols as tb                 

            where tb.banco_id='$banco_id'""")
   
    return df1
end

"""Importa a tabela de substituições para o banco de dados"""
function get_sql_bancos_subs(banco_id::Int64)::DataFrame
    df1 = query( 
        """select 
                *
            from banco_subs as tb                 

            where tb.banco_id='$banco_id'""")
   
    return df1
end

"""Importa a tabela de funções para pré-processar os bancos de dados"""
function get_sql_bancos_prep(banco_id::Int64)::DataFrame
    df1 = query(
        """select 
                *
            from banco_prep as tb                 

            where tb.banco_id='$banco_id'""")
   
    return df1
end

"""Importa a tabela de funções para pos-processar os bancos de dados após gerar o relatório"""
function get_sql_rel_pos(rel_id::Int64)::DataFrame
    df1 = query( 
        """select 
                *
            from rel_pos as tb                 

            where tb.rel_id='$rel_id'""")
   
    return df1
end


# formatação de coluna
export format_sx, format_sx_1m, format_dt_br, format_dt_sinan, format_sx_nsus, format_dt_string, format_dbf_string

"""Formata os strings do banco de dados DBF"""
function format_dbf_string(df1::DataFrame, col::String)
    return map(x -> ismissing(x) ? missing : decode(Vector{UInt8}(x), "ISO-8859-1") , df1[!, col])    
end

"""Formata o sexo 'Feminino' em 'F' """
function format_sx(df1::DataFrame, col::String)
    return map(x -> first(x, 1), df1[!, col])    
end

"""Formata o sexo 1 em 'M' e 2 em 'F' """
function format_sx_1m(df1::DataFrame, col::String)
    return map(x -> ismissing(x) ? "I" : x == 1 ? "M" : x == 2 ? "F" : "I" , df1[!, col])    
end

"""Formata o sexo 1 - Masculino em 'M' FORMATO DO NOTIFICA SUS"""
function format_sx_nsus(df1::DataFrame, col::String)
    return map(x -> ismissing(x) ? "I" : last(first(x, 4), 1) , df1[!, col])    
end


"""Formata string em data 01-12-2001 """
function format_dt_br(df1::DataFrame, col::String)
    df = DateFormat("d-m-y");
    return map(x -> ismissing(x) ? missing : Date(x,df) , df1[!, col])    
end

"""Formata string para data 20011231 """
function format_dt_sinan(df1::DataFrame, col::String)
    df = DateFormat("yyyymmdd");
    return map(x -> ismissing(x) ? missing : Date(x,df) , df1[!, col])    
end

"""Converte data em string """
function format_dt_string(df1::DataFrame, col::String)    
    return map(x -> ismissing(x) ? missing : Date(x) , df1[!, col])    
end
  

# preprocessamento # formatação de bancos
export formata_vr_covid, formata_zcd, formata_nsus_covid, formata_arbo, formata_nindnet_zika

function formata_vr_covid(df::DataFrame)
    if "Coronavírus SARS-CoV2" in names(df)
        select!(df, Not([:Resultado]))
        rename!(df, Dict(["Coronavírus SARS-CoV2" => "Resultado"]))
    end
end

"Formata o banco caso ele seja do ZDC"
function formata_zcd(df::DataFrame)    
    # colunas que detectão se o banco é zcd
    Col_chec = ["Requisição", "Dengue", "Zika", "Chikungunya"]
   
    Colunas = ["Requisição", "Paciente", "Nome da Mãe", "Data de Nascimento", "Data da Coleta", "Sexo", "IBGE Município de Residência", 
    "Endereço", "Exame", "Data de Cadastro", "Data do Recebimento", "Status Exame", "Data da Liberação", 
    "Observações do Resultado"]
    
    if issubset(Col_chec, names(df)) == false
        println("Saiu ")
    elseif issubset(Colunas, names(df)) == false
      for item in Colunas
        if issubset([item], names(df)) 
          println(item * "- Ok")
        else
          println(item * "- Erro")
        end
      end
      return "O gal foi baixado incorretamente", "Erro, não processado"
    else      
        df1= copy(df)
        select!(df, Not(["Valor CT",	"Zika", "Chikungunya"]))
        rename!(df, Dict("Dengue" => "Resultado"))
        df.Exame = map(x -> "Dengue, Biologia Molecular", df.Exame)

        df2 = copy(df1)
        select!(df2, Not(["Valor CT",	"Dengue", "Chikungunya"]))
        rename!(df2, Dict("Zika" => "Resultado"))
        df2.Exame = map(x -> "Zika, Biologia Molecular", df2.Exame)
        append!(df, df2)
        
        df2 = copy(df1)
        select!(df2, Not(["Valor CT",	"Zika", "Dengue"]))
        rename!(df2, Dict("Chikungunya" => "Resultado"))
        df2.Exame = map(x -> "Chikungunya, Biologia Molecular", df2.Exame)
        append!(df, df2)
              
        show(df)
    end
   
    
end 

"Formata o banco do notificasus para o cruzament do covid"
function formata_nsus_covid(df::DataFrame)
    comorb = ["comorb_pulm", "comorb_cardio", "comorb_renal", "comorb_hepat", "comorb_diabe", "comorb_imun", "comorb_hiv", "comorb_neopl", "comorb_tabag", "comorb_neuro_cronica", "comorb_neoplasias", "comorb_tuberculose", "comorb_obesidade", "comorb_cirurgia_bariat"]
    tel = ["telefone", "telefone_2", "telefone_3"]
    insertcols!(df, 1, :Comorbidade => "")
    insertcols!(df, 1, :telefoneR => "")
    insertcols!(df, 1, :endereco => "")

    dfCom = DataFrame(CSV.File(open(read, joinpath("data" , "linksus", "parameters", "nsus", "Comorbidades.csv"), enc"windows-1252"), delim=";"))

    dict_comorb = Dict{String,String}()
    for row in eachrow(dfCom)
        dict_comorb[row[1]] = row[2]
    end

    
    # show(select(df, [:bairro, :logradouro, :quadra, :endereco]))
    for row in eachrow(df)
        for col in comorb
            if row[col] == 1
                row[:Comorbidade] == "" ? row[:Comorbidade] = dict_comorb[col] : row[:Comorbidade] = """$(row[:Comorbidade])| \n $(dict_comorb[col])"""
            end
        end

        for col in tel
          if ~ismissing(row[col])            
            row[:telefoneR] == "" ? row[:telefoneR] = string(row[col]) : ~contains(row[:telefoneR], string(row[col])) && (row[:telefoneR] = string(row[:telefoneR], "\n", row[col]))
          end
        end

        if (~ismissing(row.bairro) && ~contains(row.bairro, "Não Encontrado")) || (~ismissing(row.logradouro) && ~contains(row.logradouro, "Não Encontrado")) 

          if ~ismissing(row.bairro) && ~contains(row.bairro, "Não Encontrado") 
              row.endereco = uppercase(row.bairro)
          end

          if ~ismissing(row.logradouro) && ~contains(row.logradouro, "Não Encontrado")
              if row.endereco != ""
                  row.endereco = string(row.endereco, " ", uppercase(row.logradouro))
              else
                  row.endereco = uppercase(string(row.logradouro))
              end 
          end 

          if  ~ismissing(row.quadra)  && ~contains(row.quadra, "Não Encontrado")
            if row.endereco != ""           
              row.endereco = string(row.endereco, " ", uppercase(row.quadra))
            else
              row.endereco = uppercase(string(row.quadra))
            end
          end

          if  ~ismissing(row.lote)  && ~contains(row.lote, "Não Encontrado")        
            if row.endereco != ""   
              row.endereco = string(row.endereco, " ", uppercase(row.lote))               
            else
              row.endereco = uppercase(string(row.lote))                
            end
          end
        end

        if row.endereco == "" 
            if ~ismissing(row.endereco_outra_cidade) 
                row.endereco = uppercase(row.endereco_outra_cidade)
            else
                row.endereco = "COLETAR NO INFORME"
            end
        elseif ~ismissing(row.endereco_outra_cidade)
            row.endereco = string(row.endereco, " ", uppercase(string(row.endereco_outra_cidade)))
        end

        if contains(row[:municipio_paciente], "PALMAS")
          row[:municipio_paciente] = "172100"
        else
          row[:municipio_paciente] = "170000"
        end

    end

    # show(select(df, [:bairro, :logradouro, :quadra, :endereco]))

    df.municipio_paciente = map(x -> parse(Int64, x), df.municipio_paciente )

    # println(df)
    
end

"""Formata o banco de Chikungunya e dengue do sinan net"""
function formata_arbo(df::DataFrame)

    cols = ["RES_CHIKS1", "RES_CHIKS2", "RESUL_SORO", "RESUL_NS1", "RESUL_VI_N", "RESUL_PCR_"]

    insertcols!(df, 1, :ExameR => "")

    for row in eachrow(df)
        for col in cols
            if  ~ismissing(row[col]) && row[col] in ["1", "2"]   
                row[:ExameR] = "Sim"
            end
        end
    end
    
end

"""Formata o banco NINDNET para extrair só zika"""
function formata_nindnet_zika(df::DataFrame)
    filter!([:ID_AGRAVO] => x -> x == "A928", df)    
end

# Relatórios
# Funções de carregamento
export carregar_csv

"Carrega os csv para gerar os relatórios"
function carregar_csv(bd::String)
  file = joinpath("data", "linksus", "importado", bd * ".csv")
  df = DataFrame(CSV.File(open(read, file), delim=";"))
  if "index" in names(df)
    if contains(string(eltype(df.index)), "String")
        df.index = map(x -> parse(Int64, x), df.index)
    end
  end
  return df
end








end