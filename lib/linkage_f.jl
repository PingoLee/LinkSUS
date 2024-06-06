module linkage_f
using Dates, SQLite, DataFrames

export get_defs_prob
# carregar definições
function get_defs_prob(db::SQLite.DB)
    sql = """
      select * from defs_prob where id = 1
    """
    df = DBInterface.execute(db, sql) |> DataFrame
  
    return df[1, :]
end

# funções textuais
export soundex_br, dateaval, metaphone_br
function encode(chr::SubString{String})
    if contains("BFPV", chr)
        return "1"
    elseif contains("CGJKQSXZ", chr)
        return "2"
    elseif contains("DT", chr)
        return "3"
    elseif "L" == chr
        return "4"   
    elseif contains("MN", chr)
        return "5" 
    elseif "R" == chr
        return "6"
    else 
        return ""
    end
end

"""Soundex modificado para o brasil"""
function soundex_br(s::String)::String
    output = ""
    previous_encoding = ""
    index = 0    
    for chr in rsplit(uppercase(s), "")      
        encoding = encode(chr)     
        if index == 0
            index += 1    
            output = chr   
        elseif index <= 3           
            if encoding != "" && encoding != previous_encoding                                 
                output = string(output, encoding)
                index += 1              
            end       
        else            
            break
        end       
    end
    # Append with zeros if needed    
    if index < 4   
        output = string(output, repeat('0', (4 - index)))
    end
    return output
end

function metaphone_br(Nome::String; Tamanho::Int64=10)::String
    # Separa as letras num array 
    Nome = filter(x -> isletter(x) || isspace(x), Nome)
    Nome = uppercase(Nome)
    Nome = strip(Nome)
    Nome = replace(Nome, "LH" => "1", "NH" => "3", "XC" => "S", "SCH" => "X", " DA " => " ", " DE " => " ", " DO " => " ", " DAS " => " ", " DOS " => " ", " E " => " ")
      
    Chars = rsplit(Nome, "")
    N_Letras = size(Chars, 1)
    Buffer = ""
    É_Vogal = ["A", "E", "I", "O", "U"]
    # Make sure the word is at least two characters in length
    if N_Letras > 2           
        LtPlus = ""
        U_Lt  = N_Letras - 1
        i = 1
        while i <= U_Lt            
            (i + 1) == N_Letras ? LtPlus = " " : LtPlus = Chars[i + 1]

            if Chars[i] in ["A", "E", "I", "O", "U"]
                if i == 1 || Chars[i - 1] == " "
                    Buffer = string(Buffer, Chars[i])
                elseif LtPlus == "U"
                    Buffer = string(Buffer, "L")
                    i += 1
                end                
            elseif Chars[i] in ["1", "3", "B", "D", "F", "J", "K", "L", "M", "P", "T", "V"]
                Buffer = string(Buffer, Chars[i])
                LtPlus == Chars[i] ? i += 1 : i
            elseif Chars[i] == "G"
                if LtPlus == "E" && LtPlus == "I"
                    Buffer = string(Buffer, "J")
                    i += 1
                elseif LtPlus == "R"
                    Buffer = string(Buffer, "GR")
                    i += 1
                else
                    Buffer = string(Buffer, "G")
                    i += 1
                end
            elseif Chars[i] ==  "R"
                Buffer = string(Buffer, "2")
            elseif Chars[i] == "Z"
                if i == U_Lt || LtPlus == " " 
                    Buffer = string(Buffer, "S")
                else
                    Buffer = string(Buffer, "Z")
                end
            elseif Chars[i] == "N"
                if i == U_Lt || LtPlus == " "
                    Buffer = string(Buffer, "M")
                else
                    Buffer = string(Buffer, "N")
                end
            elseif Chars[i] == "S"
                if i == 1 || Chars[i - 1] == " "
                    Buffer = string(Buffer, "S")
                elseif  i != 0 && i != U_Lt &&
                    LtPlus in É_Vogal &&
                    Chars[i - 1] in É_Vogal
                        Buffer = string(Buffer, "Z")
                elseif i + 2 != U_Lt && LtPlus == "C"
                    LtPlus2 = Chars[i + 2]
                    if LtPlus2 == "E" || LtPlus2 == "I"
                        Buffer = string(Buffer, "S")
                        i += 2
                    elseif LtPlus2 == "A" || LtPlus2 == "U" || LtPlus2 == "O"
                        Buffer = string(Buffer, "SC")
                        i += 2
                    else
                        Buffer = string(Buffer, "S")
                    end
                else
                    Buffer = string(Buffer, "S")
                end

            elseif Chars[i] == "X"
                if i == 2 && Chars[i - 1] in É_Vogal
                    if Chars[i - 1] == "E"
                        Buffer = string(Buffer, "S")
                    elseif Chars[i - 1] == "I"
                        Buffer = string(Buffer, "X")
                    else
                        Buffer = string(Buffer, "KS")
                    end
                else
                    Buffer = string(Buffer, "X")
                end

            elseif Chars[i] == "C"
                if i + 1 != U_Lt && (LtPlus == "E" || LtPlus == "I")
                    Buffer = string(Buffer, "S")
                    i += 1
                elseif i + 1 != U_Lt && LtPlus == "H"
                    Buffer = string(Buffer, "X")
                    i += 1
                else
                    Buffer = string(Buffer, "K")
                end

            elseif Chars[i] == "H" # Acho que dá pra mover lá pra cima?
                if i == 0 && LtPlus in É_Vogal
                    Buffer = string(Buffer, LtPlus)
                    i += 1
                end
            elseif Chars[i] == "Q"
                if LtPlus == "U"
                    Buffer = string(Buffer, "K")
                    i += 1
                else
                    Buffer = string(Buffer, "K")
                end

            elseif Chars[i] ==  "W"
                    if LtPlus in É_Vogal
                        Buffer = string(Buffer, "V")
                        i += 1
                    end       
            end

            # if the buffer size meets the length limit, then exit the loop
            if length.(Buffer) >= Tamanho
                break
            end

            i += 1
        end
    else
        # Set the return value
        return Nome
    end

    # Return the computed soundex
    return Buffer

end


# comparações
export levenshtein, dateaval, avalabrev, jaro
"Algoritmo que compara duas datas"
function dateaval(d1::Date, d2::Date)
    check = 0
    AnoIgual = false
    res = 0

    d1d = split(replace(string(d1), "-" => ""),"")
    d2d = split(replace(string(d2), "-" => ""),"")

    d1 == d2 && (return 100)
    
    if year(d1) == year(d2) 
        AnoIgual = true
        if month(d1) == day(d2) && month(d2) == day(d1)
            return 95 #'verifica se houve inversão de data
        end

        for i=5:8
            d1d[i] == d2d[i] && (check += 1)
        end

        check == 3 && (return 88)               
    end

    #'18 pontos com o dia
    # '12 ponto com o mês
    # '30 pontos com ano

    # verifica o dia de nascimento 
    if day(d1) == day(d2)
        res = res + 18
    else
        if AnoIgual
           if 2 >  (day(d1) - day(d2)) > -2 # diferença de 1 dia
            res = res + 6
           elseif d1d[7] == d2d[8] && d1d[8] == d2d[7]
            res = res + 8
           end
        else
            d1d[7] == d2d[7] && (res = res + 4)
            d1d[8] == d2d[8] && (res = res + 6)
        end
    end

    # verifica o month de nascimento 
    if month(d1) == month(d2)
        res = res + 12
    else
        if AnoIgual
           if 2 >  (month(d1) - month(d2)) > -2 # diferença de 1 dia
            res = res + 5
           elseif d1d[5] == d2d[6] && d1d[6] == d2d[5]
            res = res + 6
           end
        else
            d1d[5] == d2d[5] && (res = res + 3)
            d1d[6] == d2d[6] && (res = res + 4)
        end
    end

    #'Ano
    #'Detalha eventual erro na digitação de um dos dígitos do ano
    #'identificadiferença entre anos
    (year(d1) - year(d2)) in [1, -1, 10, -10] ? DifA = true : DifA = false

    if AnoIgual
        if res == 0 #' O ano é igual, mas o dia e mês não 
            res = 20
        elseif res < 10 #' O ano é igual, mas o restante é bem diferente
            res = 22
        else #' O ano é igual e o restante é diferente (se for tudo igual já foi detectado anteriormente)
            res = res + 25
        end
    elseif d1d[3] == d2d[3] || d1d[4] == d2d[4] || DifA # ' Apenas um dos dígitos do ano é igual
        if res == 30
            if DifA # '(ex.: 1955 e 1956 ou 1965 e 1955)
                res = 49
            else
                res = 45
            end
        elseif DifA # '(ex.: 1955 e 1956 ou 1965 e 1955)
            res = res + 18
        elseif res > 20
            res = res + 12
        else
            res = res + 8
        end
    end

    #'Interpreta
    if res == 0 
        return 0
    else
        return round(Int, res / 6 * 10)
    end
end
function dateaval(d1::Missing, d2::Date)
    return missing
end
function dateaval(d1::Date, d2::Missing)
    return missing
end
function dateaval(d1::Missing, d2::Missing)
    return missing
end
function dateaval(d1::String, d2::String) 
    dateaval(Date(d1),Date(d2))
end
function dateaval(d1::Missing, d2::String)
    return missing
end
function dateaval(d1::String, d2::Missing)
    return missing
end
function dateaval(d1::String, d2::Date) 
    dateaval(Date(d1),d2)
end
function dateaval(d1::Date, d2::String) 
    dateaval(d1,Date(d2))
end


"Avalia se o nome é uma abreviação"
function avalabrev(Nm1::String, Nm2::String)       
    #' prepara os nomes
    Vetor1 = split(Nm1, " ") ; Ul1 = length(Vetor1) ; Tamanho1 = length(Nm1)
    Vetor2 = split(Nm2, " ") ; Ul2 = length(Vetor2) ; Tamanho2 = length(Nm2)    
    Tamanho1 - Tamanho2 < 0 ? DIF = Tamanho2 - Tamanho1 : DIF = Tamanho1 - Tamanho2
    (Ul1 == 1 || Ul2 == 1) && (return "Simples") #Tem apenas um nome
    if Ul2 < Ul1
        transicao1 = Vetor1 ; Ult = Ul1
        Vetor1 = Vetor2 ; Ul1 = Ul2
        Vetor2 = transicao1 ; Ul2 = Ult
    end
    #Procura breviação
    iniciais3 = ""
    Abreviado = false
    for i = 1:Ul1
        length(Vetor1[i]) == 1 && (Abreviado = true) 
    end
    for i = 1 : Ul2
        length(Vetor2[i]) == 1 && (Abreviado = true) 
    end
    #'Monta iniciais
    iniciais1 = "" ; iniciais2 = ""
    for i = 1 : Ul1
        iniciais1 = iniciais1 * first(Vetor1[i],1)
        iniciais2 = iniciais2 * first(Vetor2[i],1)
    end
    #Avalia quando há a mesma quantidade de nomes
    if Ul1 == Ul2
        Similaridade1 = levenshtein(iniciais1, iniciais2)
        if iniciais1 == iniciais2 
            if Abreviado
                return "Abrev" #'Iniciais identicas com nome abreviado
            else
                return "Igual" # 'Iniciais identicas sem abreviação
            end
        elseif Similaridade1 < 76
            if Vetor1[1] == Vetor2[1]
                return "AbrevZ" # muitas iniciais erradas
            else
                return "AbrevX" # muitas iniciais erradas
            end
        else
            return "Abrev?" #Pode estar abreviado
        end
    else
        for i = Ul1 : Ul2
            iniciais3 = iniciais2
            iniciais3 = iniciais3 * first(Vetor2[i], 1)
        end
    end
    # Avalia quando a diferença na quantidade de nome faltantes
    if iniciais1 == iniciais2 
        return "dif1" #Não apresenta o último nome
    elseif first(Vetor1[1], 1) == first(Vetor2[1], 1) && first(Vetor1[Ul1], 1) == first(Vetor2[Ul2], 1)
        if levenshtein(iniciais1, iniciais3) > 90 
            return "dif2"
        else
            return "dif"
        end
    else
        if levenshtein(iniciais1, iniciais3) < 76
            return "dif"
        else
            return "dif2"
        end
    end
end

 
"""
levenshtein()
Creates the levenshtein distance
The levenshtein distance is the minimum number of operations (consisting of insertions, deletions, 
substitutions of a single character) required to change one string into the other.
"""
## Source: https://github.com/matthieugomez/StringDistances.jl/blob/main/src/distances/edit.jl
function levenshtein(s1::String, s2::String, modf::Bool=false)    
    len1, len2 = length(s1), length(s2)    
    if len1 > len2
        s1, s2 = s2, s1
        len1, len2 = len2, len1
    end        
    # first row of matrix set to distance between "" and s2[1:i]       
    v = collect(1:(len2))
    current = 0
    for (i1, ch1) in enumerate(s1)           
        left = current = i1 - 1            
        for (i2, ch2) in enumerate(s2)                
            above = current
            # cost on diagonal (substitution)
            current = left
            @inbounds left = v[i2]
            if ch1 != ch2
                # minimum between substitution, deletion and insertion
                current = min(current + 1, above + 1, left + 1)
            end                
            @inbounds v[i2] = current
        end           
    end  
    len1 > len2 ? (Max = len1 ; Min = len2) : (Max = len2 ; Min = len1)
    if modf && (Max - Min) > 3       
        return round(Int, (1 - ((current - (Max - Min)) / Min)) * 100)   # calcula com a modificação
    else
        return round(Int, (1 - (current / Max)) * 100)
    end
end
function levenshtein(s1::String, s2::Missing, modf::Bool=false)    
   return missing
end
function levenshtein(s1::Missing, s2::String, modf::Bool=false)    
    return missing
end
function levenshtein(s1::Missing, s2::Missing, modf::Bool=false)    
    return missing
end

#levenshtein("IGOR MARTINS CARDOSO", "IGOR LIMA", true)

"""
    Jaro()
Creates the Jaro distance
The Jaro distance is defined as
``1 - (m / |s1| + m / |s2| + (m - t) / m) / 3``
where ``m`` is the number of matching characters and 
``t`` is half the number of transpositions.
"""
## Source: https://github.com/matthieugomez/StringDistances.jl/blob/main/src/distances/edit.jl
function jaro(s1::String, s2::String)::Int64    
    len1, len2 = length(s1), length(s2)
    if len1 < len2
        s1, s2 = s2, s1
        len1, len2 = len2, len1
    end
    # If both iterators empty, formula in Wikipedia gives 1, but it makes more sense to set it to s1 == s2
    len2 > 0 || return 0
    d = max(0, div(len2, 2) - 1)
    flag = fill(false, len2)
    ch1_match = Vector{eltype(s1)}()
    for (i1, ch1) in enumerate(s1)
        for (i2, ch2) in enumerate(s2)
            # for each character in s1, greedy search of matching character in s2 within a distance d
            i2 >= i1 - d || continue
            i2 <= i1 + d || break
            if ch1 == ch2 && !flag[i2] 
                flag[i2] = true
                push!(ch1_match, ch1)
                break
            end
        end
    end
    if isempty(ch1_match)
        return 1.0
    else
        #  m counts number matching characters
        m = length(ch1_match)
        # t/2 counts number transpositions
        t = 0
        i1 = 0
        for (i2, ch2) in enumerate(s2)
            if flag[i2]
                i1 += 1
                @inbounds t += ch2 != ch1_match[i1]
            end
        end
        return round(((m / len1 + m / len2 + (m - 0.5 * t) / m) / 3) * 100)
    end
end
function jaro(s1::String, s2::Missing)    
    return missing
end
function jaro(s1::Missing, s2::String)    
    return missing
end
function jaro(s1::Missing, s2::Missing)    
    return missing
end

# jaro("RAFAEL BRUSTULIN", "RAFAEL BRUSTULIN")
# jaro("RAFAEL BRUSTULIN", "RAFAEL DE BRUSTULIN")
# jaro("RAFAEL BRUSTULIN", "RAFAEL BRUSTOLEM")
# jaro("RAFAEL BRUST", "RAFAEL BRUSTULIN")
# jaro("RAFAEL BRUSTULIN", "")

# auxilio de calculo
export calc_prob, soma_string, levsn

"""Calcula o score probabilistico (definições fixas)
O df1 pode vir sem as informações dos cálculos deterministicos e data de nascimento
"""
function calc_prob(df1::DataFrame, db::SQLite.DB)
  # baixa as informações da data de registro (talvez fica bom para bases muito grandes IMPLEMENTAR)

  sql = """
    select * from defs_prob where id = 1
  """
  df = DBInterface.execute(db, sql) |> DataFrame

  prob = df[1,:]

  local n_logp = log(2, prob.npm / prob.npu)
  local n_logn = log(2, (100 - prob.npm) / (100 - prob.npu)) # O log dá negativo
  local nm_logp = log(2, prob.mpm / prob.mpu)
  local nm_logn = log(2, (100 - prob.mpm) / (100 - prob.mpu))
  local dn_logp = log(2, prob.dnpm / prob.dnpu)
  local dn_logn = log(2, (100 - prob.dnpm) / (100 - prob.dnpu))
  local lim_n = prob.lim_n
  local lim_m = prob.lim_m
  local lim_dn = prob.lim_dn
  insertcols!(df1, 2, :escore_prob => 0.0)

  for row in eachrow(df1)
    local lvn = levenshtein(row.nome1, row.nome2)
    local lvm = levenshtein(row.nm_m1, row.nm_m2)

    local reln = 0
    ismissing(lvn) ? reln = 0.5 * n_logn : lvn >= lim_n ? reln = (lvn/100) * n_logp : lvn > 30 ? reln = (1 - (lvn/100)) * n_logn : reln = n_logn

    local relnm = 0
    ismissing(lvm) ? relnm = 0.5 * nm_logn : lvm >= lim_m ? relnm = (lvm/100) * nm_logp : lvm >= 30 ? relnm = (1 - (lvm/100)) * nm_logn : relnm = nm_logn

    local reldm = 0
    ismissing(row.distdn) ? reldm = 0.5 * dn_logn : row.distdn >= lim_dn ? reldm = (row.distdn/100) * dn_logp : row.distdn >= 30 ? reldm = (1 - (row.distdn/100)) * dn_logn : reldm = dn_logn

    row.escore_prob = round(reln + relnm + reldm, digits=2)
  end


  return DataFrames.select(df1, [:id, :escore_prob])
 

end

"""Soma os números de um array quando formato em número ex. ["2", "0", "R"] = 2"""
function soma_string(elm)
    soma = 0
    for i in elm
        sm = tryparse(Int64, i)
        ~isnothing(sm) && (soma += sm)
    end
    return soma
end

"""Calcula a distância de levenshtein do segundo nome"""
function levsn(s1::String, s2::String)
    vect1 = split(s1, " ")
    vect2 = split(s2, " ")

    if length(vect1) < 2 || length(vect2) < 2 
        return 0
    else
        return levenshtein(string(vect1[2]), string(vect2[2]))
    end
    
end



# Blocagem
export block_sql_mult, block_sql_sing
function block_sql_mult(n::Int64, tam::Int64)  
    local results = Channel(32);
    local steps = convert(Int64, round(tam/n)) + 1
    agora = now()      
   
    function do_work(i)            
        # Blocagem
        println("Processo $i")
        db = SQLite.DB(joinpath("data", "linksus.db"))
        inicio = (i * steps) - steps
        fim = i * steps
        sql = """
            SELECT
                b1."index" as id1,
                b2."index" as id2,
                b1.nome as nome1,
                b2.nome as nome2,
                b1.nome_mae as nm_m1,
                b2.nome_mae as nm_m2,
                b1.dn as dn1,
                b2.dn as dn2
                    
            from b1_proc as b1            
                inner join b2_proc as b2 on b2.dn = b1.dn or 
                (b2.sxpn = b1.sxpn and b2.sxun = b1.sxun and b2.sxpnm = b1.sxpnm and not b2.sxpnm is null) or
                (b2.sxpn = b1.sxpn and b2.sxsn = b1.sxsn and b2.sexo = b1.sexo) or
                (b2.sxun = b1.sxun and strftime('%Y',b2.dn) = strftime('%Y',b1.dn))

            where
                b1."index" >= $inicio and b1."index" <= $fim and
                not b1."index" is null and not b2."index" is null
                
            order by id1, id2
        """
        
        df = DBInterface.execute(db, sql) |> DataFrame
        #show(df)
                   
        put!(results, df)
        
    end;

    Threads.@threads for i in 1:n # start 4 tasks to process requests in parallel
        #errormonitor(@async do_work(i))
        #@async begin
        do_work(i)
        
        #end
    end

    local stps = copy(n)
    local dff = nothing
    while stps > 0 # print out results
        df = take!(results)   
        if dff == nothing && size(df, 1) > 0
            dff = copy(df)
            allowmissing!(dff)
        else
            size(df, 1) > 0 && (append!(dff, df, promote=true))
        end        
        stps = stps - 1
    end
    
    println("Levou " * string(Dates.format(convert(DateTime, now() - agora), "MM:SS")))

    return dff
end
function block_sql_mult(n::Int64, tam::String)  
    block_sql_mult(n, parse(Int64, tam))
end

function block_sql_sing()
    # Blocagem
  sql = """
  SELECT
    b1."index" as id1,
    b2."index" as id2,
    b1.nome as nome1,
    b2.nome as nome2,
    b1.nome_mae as nm_m1,
    b2.nome_mae as nm_m2,
    b1.dn as dn1,
    b2.dn as dn2
        
  from b1_proc as b1
    inner join b2_proc as b2 on b2.dn = b1.dn or 
    (b2.sxpn = b1.sxpn and b2.sxun = b1.sxun and b2.sxpnm = b1.sxpnm and not b2.sxpnm is null) or
    (b2.sxpn = b1.sxpn and b2.sxsn = b1.sxsn and b2.sexo = b1.sexo) or
    (b2.sxun = b1.sxun and strftime('%Y',b2.dn) = strftime('%Y',b1.dn))

  where
    not b1."index" is null and not b2."index" is null
    
  order by id1, id2
  """

return DBInterface.execute(db, sql) |> DataFrame

end

#include("lib/linkage_f.jl")
#linkage_f.block_sql(6, 1896)

end
