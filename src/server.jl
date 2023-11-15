const DEFAULT_ADDRESS = URI("http://localhost:4100")

mutable struct Server
    cmd::Cmd
    address::URI
    region::String
    config::Dict{Any,Any}
    process::Union{Process,Nothing}
    config_path::Union{String,Nothing}
    verbose::Bool
end

function server_uri(str::AbstractString)
    return startswith(str, r".*://") ? URI(str) : URI("http://" * str)
end
server_uri(uri::URI) = uri

"""
    GoAWS.Server(; cmd=goaws_jll.goaws(),
                 config=GoAWS.default_config(),
                 address=GoAWS.DEFAULT_ADDRESS,
                 region="us-east-2",
                 detach::Bool=false,
                 verbose::Bool=false)

A data structure for managing a `goaws` server process.

The passed-in `config` will be mutated in-place to add the `host` and `port` from `address`,
and the `region`.

Supports `run`, as well as `kill`, `getpid`, `success`, `process_exited`, and `process_running`
by forwarding to the process created by `run`.

Can also be used with [`with_go_aws`](@ref).
"""
function Server(; cmd=goaws(),
                config=default_config(),
                address=DEFAULT_ADDRESS,
                region="us-east-2",
                detach::Bool=false,
                verbose::Bool=false)
    address = server_uri(address)
    config["Local"]["Host"] = address.host
    config["Local"]["Port"] = address.port
    config["Local"]["Region"] = region
    if detach
        cmd = Base.detach(cmd)
    end
    return Server(cmd, address, region, config, nothing, nothing, verbose)
end

function Base.show(io::IO, s::Server)
    show(io, Server)
    print(io, "(\"", s.address, "\"")
    if !isnothing(s.process) && process_running(s.process)
        print(io, ", ")
        printstyled(io, "running"; color=:green, bold=true)
    elseif !isnothing(s.process) && process_exited(s.process)
        print(io, ", ")
        printstyled(io, "exited"; color=:magenta, bold=true)
        if s.process.exitcode == 0
            printstyled(io, " successfully"; color=:magenta, bold=true)
        else
            printstyled(io, " unsuccessfully (exitcode: $(s.process.exitcode))";
                        color=:magenta, bold=true)
        end
    else
        print(io, ", unstarted")
    end
    return print(io, ")")
end

function Base.run(s::Server; wait=true)
    path, io = mktemp()
    s.config_path = path
    YAML.write(io, s.config)
    close(io)
    if s.verbose
        stdout = Base.stdout
        stderr = Base.stderr
    else
        stdout = devnull
        stderr = devnull
    end
    s.process = run(pipeline(`$(s.cmd) --config $(s.config_path)`; stdout, stderr); wait)
    return s
end

function _check_initialized(s::Server)
    return isnothing(s.process) &&
           error("invalid operation on unstarted server object $(s). Call `run` to start the server first.")
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
function with_go_aws(f; address=DEFAULT_ADDRESS, region="us-east-2", kw...)
    address = server_uri(address)
    server = Server(; address, region, kw...)
    try
        run(server; wait=false)
        sleep(0.5)  # give the server just a bit of time, though it is very fast to start
        config = GoAWSConfig(address, region)
        f(config)
    finally
        # Make sure we kill the server even if a test failed.
        kill(server)
    end
end
