module GoAWS

using AWS
using URIs
using YAML
using Base: Process

export GoAWSConfig

Base.include_dependency(joinpath(@__DIR__, "default_config.yaml"))
const DEFAULT_CONFIG = YAML.load_file(joinpath(@__DIR__, "default_config.yaml"))
default_config() = deepcopy(DEFAULT_CONFIG)

export GoAWSConfig
include("aws_interop.jl")

export with_go_aws
include("server.jl")

end
