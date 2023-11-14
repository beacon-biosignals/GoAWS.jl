module GoAWS

using AWS
using URIs
using YAML
using Base: Process
using goaws_jll

# We load this at precompilation time, so we need to recompile if it is stale
Base.include_dependency(joinpath(@__DIR__, "default_config.yaml"))
const DEFAULT_CONFIG = YAML.load_file(joinpath(@__DIR__, "default_config.yaml"))

"""
    GoAWS.default_config() -> Dict{Any,Any}

Provides a copy of the default configuration used in [`Server`](@ref) and [`with_go_aws`](@ref).
"""
default_config() = deepcopy(DEFAULT_CONFIG)

export GoAWSConfig
include("aws_interop.jl")

export with_go_aws
include("server.jl")

end
