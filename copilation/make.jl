using PackageCompiler

include("packages.jl")

PackageCompiler.create_sysimage(
  PACKAGES,
  sysimage_path = "copilation/sysimg.so",
  precompile_execution_file = "copilation/precompile.jl",
  cpu_target = PackageCompiler.default_app_cpu_target()
)