const DEFAULT_ADDRESS = URI("http://localhost:4100")

mutable struct Server
    cmd::Cmd
    address::URI
    region::String
    config::Dict{Any,Any}
    process::Union{Process, Nothing}
    config_path::Union{String, Nothing}
end

# TODO- use JLL once https://github.com/JuliaPackaging/Yggdrasil/pull/7678 is merged
"""
    GoAWS.Server(; cmd=`/Users/eph/goaws/goaws`,
                 config=GoAWS.default_config(),
                 address::URI=GoAWS.DEFAULT_ADDRESS,
                 region="us-east-2",
                 detach::Bool=false)

A data structure for managing a `goaws` server process.

The passed-in `config` will be mutated in-place to add the `host` and `port` from `address`,
and the `region`.

Supports `run`, `kill`, `getpid`, `process_exited`, and `process_running`.
Can also be used with [`with_go_aws`](@ref).
"""
function Server(; cmd=`/Users/eph/goaws/goaws`,
                config=default_config(),
                address::URI=DEFAULT_ADDRESS,
                region="us-east-2",
                detach::Bool=false)

    config["Local"]["Host"] = address.host
    config["Local"]["Port"] = address.port
    config["Local"]["Region"] = region
    if detach
        cmd = Base.detach(cmd)
    end
    return Server(cmd, address, region, config, nothing, nothing)
end

function Base.run(s::Server; wait=true)
    path, io = mktemp()
    s.config_path = path
    YAML.write(io, s.config)
    close(io)
    s.process = run(`$(s.cmd) -config $(s.config_path)`; wait)
    return s
end

function _check_initialized(s::Server)
    isnothing(s.process) && error("invalid operation on unstarted server object $(s). Call `run` to start the server first.")
end

function Base.kill(s::Server)
    _check_initialized(s)
    rm(s.config_path; force=true)
    s.config_path = nothing
    return kill(s.process)
end

function Base.getpid(s::Server)
    _check_initialized(s)
    return getpid(s.process)
end

function Base.process_exited(s::Server)
    _check_initialized(s)
    return process_exited(s.process)
end

function Base.process_running(s::Server)
    _check_initialized(s)
    return process_running(s.process)
end

"""
    with_go_aws(f; address=DEFAULT_ADDRESS, region="us-east-2", kw...)

Starts up a GoAWS server, runs `f(go_aws_config::AbstractAWSConfig)`, with an AWS.jl-compatible config pointing to a live GoAWS server,
and destroys the server when `f()` finishes or errors.
"""
function with_go_aws(f; address=DEFAULT_ADDRESS, region="us-east-2",  kw...)
    server = Server(; address, region, kw...)
    try
        run(server; wait=false)
        sleep(0.5)  # give the server just a bit of time, though it is fast to start
        config = GoAWSConfig(address, region)
        f(config)
    finally
        # Make sure we kill the server even if a test failed.
        kill(server)
    end
end
