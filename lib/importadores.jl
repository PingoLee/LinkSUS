module importadores

using DataFrames, CSV, DBFTables, XLSX, SQLite
using StringEncodings, Dates

export get_csv_gal
# coleções de funções para importar arquivos
"""Importa os arquivos do gal"""
function get_csv_gal(file::String)::DataFrame
    return DataFrame(CSV.File(open(read, file, enc"windows-1252"), delim=";"))
end

"""Importa os arquivos em dbf"""
function get_dbf(file::String)::DataFrame
    return DataFrame(DBFTables.Table(file))
end


# importa do sql
export get_sql_bancos_defs, get_sql_bancos_cols, get_sql_bancos_subs, get_sql_bancos_prep

"""importa o dict dos bancos (b1 e b2)"""
function get_sql_bancos_defs(db::SQLite.DB, crz::String)
    df1 = DBInterface.execute(db, 
        """select 
                tb.nome, bd.*
            from opc_cruzamento as tb 
                inner join bancos as bd on bd.id = tb.b1_id 

            where tb.id='$crz'""") |> DataFrame 

    df2 = DBInterface.execute(db, 
        """select 
                tb.nome, bd.*
            from opc_cruzamento as tb 
                inner join bancos as bd on bd.id = tb.b2_id 

            where tb.id='$crz'""") |> DataFrame 

    insertcols!(df1, 1, :file => "file1_id")
    insertcols!(df2, 1, :file => "file2_id")

    return df1[1,:], df2[1,:]
end

"""Importa as definições para formatação e checagem das colunas dos bancos de dados"""
function get_sql_bancos_cols(db::SQLite.DB, banco_id::Int64)::DataFrame
    df1 = DBInterface.execute(db, 
        """select 
                *
            from banco_cols as tb                 

            where tb.banco_id='$banco_id'""") |> DataFrame 
   
    return df1
end

"""Importa a tabela de substituições para o banco de dados"""
function get_sql_bancos_subs(db::SQLite.DB, banco_id::Int64)::DataFrame
    df1 = DBInterface.execute(db, 
        """select 
                *
            from banco_subs as tb                 

            where tb.banco_id='$banco_id'""") |> DataFrame 
   
    return df1
end

"""Importa a tabela de funções para pré-processar os bancos de dados o banco de dados"""
function get_sql_bancos_prep(db::SQLite.DB, banco_id::Int64)::DataFrame
    df1 = DBInterface.execute(db, 
        """select 
                *
            from banco_prep as tb                 

            where tb.banco_id='$banco_id'""") |> DataFrame 
   
    return df1
end



# formatação de coluna
export format_sx, format_sx_1m, format_dt, format_dt_sinan, format_sx_nsus, format_dt_string


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
function format_dt(df1::DataFrame, col::String)
    df = DateFormat("d-m-y");
    return map(x -> ismissing(x) ? missing : string(Date(x,df)) , df1[!, col])    
end

"""Formata string em data 20011231 """
function format_dt_sinan(df1::DataFrame, col::String)
    df = DateFormat("yyyymmdd");
    return map(x -> ismissing(x) ? missing : string(Date(x,df)) , df1[!, col])    
end

"""Converte data em string """
function format_dt_string(df1::DataFrame, col::String)
    df = DateFormat("yyyymmdd");
    return map(x -> ismissing(x) ? missing : string(x) , df1[!, col])    
end
  

# preprocessamento # formatação de bancos
export formata_vr_covid, formata_zcd

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


# Relatórios
# Funções de carregamento
export carregar_csv

"Carrega os csv para gerar os relatórios"
function carregar_csv(bd::String)
  file = joinpath("data", "linksus", "importado", bd * ".csv")
  return DataFrame(CSV.File(open(read, file)))
end

export gerar_relatorio

"gera o relatorio"
function gerar_relatorio()

end

end