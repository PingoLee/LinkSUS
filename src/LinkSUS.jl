module LinkSUS

using Genie
using Revise
using PrecompileTools

PrecompileTools.verbose[] = true

const up = Genie.up
export up

function main()
  Genie.genie(; context = @__MODULE__)
end

end
