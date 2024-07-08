(pwd() != @__DIR__) && cd(@__DIR__) # allow starting app from bin/ dir

using LinkSUS
const UserApp = LinkSUS
LinkSUS.main()

LinkSUS.Genie.isrunning() || up(port=8001)

using LinkSUS.PrecompileTools: @setup_workload, @compile_workload

@setup_workload begin
  
  @compile_workload begin
    LinkSUS.HTTP.request("GET", "http://127.0.0.1:8001/session") |> println
    LinkSUS.HTTP.request("GET", "http://127.0.0.1:8001/") |> println
    LinkSUS.Pag_ini.cruzamento(1) |> json  |> println

  end
end

