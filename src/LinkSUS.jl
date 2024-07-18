module LinkSUS

using PrecompileTools: @setup_workload, @compile_workload, verbose

using Genie

const up = Genie.up
export up

function main()
  Genie.genie(; context = @__MODULE__)
end

ENV["PRECOMPILE"] == "true" && begin
  verbose[] = true

  @setup_workload begin
    main()

    using Genie.Router

    using Genie.Requests
    using Genie, GenieSession, GenieSessionFileSession, Genie.Renderer.Json

    using HTTP

    @compile_workload begin
      
      Genie.isrunning() || up(port=8001)

      HTTP.request("GET", "http://127.0.0.1:8001/") 
      HTTP.get("http://127.0.0.1:8001/get_load")
      HTTP.get("http://127.0.0.1:8001/get_bd?cruzamento=2")

      down()
      
    end
  end

  println("Server compile done")
end
    


end
