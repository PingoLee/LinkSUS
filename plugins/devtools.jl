using GenieDevTools
using Stipple
using GenieAutoReload

if ( Genie.Configuration.isdev() )
  Genie.config.log_to_file = true
  Genie.Logger.initialize_logging()

  GenieDevTools.register_routes()
  Stipple.deps!(GenieAutoReload, GenieAutoReload.deps)
  autoreload(pwd())
end
