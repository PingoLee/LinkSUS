module LinkSUS

using PrecompileTools
using Genie

const up = Genie.up
export up

function main()
  Genie.genie(; context = @__MODULE__)
end

# @setup_workload begin

#   @compile_workload begin
#     main()
#   end
# end

end
