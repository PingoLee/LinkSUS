module LinkSUS

using PrecompileTools: @setup_workload, @compile_workload, verbose

using Genie

const up = Genie.up
export up

function main()
  Genie.genie(; context = @__MODULE__)
end


# LinkSUS.HTTP.request("GET", "http://127.0.0.1:8001/session") |> println

verbose[] = true

@setup_workload begin
  using Genie.Router

  using Genie.Requests
  using Genie, GenieSession, GenieSessionFileSession, Genie.Renderer.Json

  using HTTP


  @compile_workload begin
    route("/session") do
      s = session(params())
      if !haskey(s.data, :number)
          return Genie.Renderer.redirect(:get) # index / is associated with symbol :get
      end
      "Your random number is $(s.data[:number])
      <br> <a href='/clear_data'>Clear data</a>"
    
    end

    Genie.isrunning() || up(port=8001)

    HTTP.request("GET", "http://127.0.0.1:8001/session") 

    down()
    
  end
end

println("Server compile done")
    


end
