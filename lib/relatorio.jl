module relatorio

using DataFrames, CSV, DBFTables, XLSX, SQLite
using StringEncodings, Dates

# Funções de carregamento
export carregar_csv
function carregar_csv(bd::String)
  file = joinpath("data", "linksus", "importado", bd * ".csv")
  return DataFrame(CSV.File(open(read, file)))
end

export gerar_relatorio

"gera o relatorio"
function gerar_relatorio()

end


end # fim do modulo