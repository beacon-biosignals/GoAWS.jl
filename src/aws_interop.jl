"""
    GoAWSConfig <: AWS.AbstractAWSConfig
    GoAWSConfig(; endpoint=GoAWS.DEFAULT_ADDRESS, region="us-east-2")
    GoAWSConfig(s::Server)

Constructs an `AbstractAWSConfig` for use with AWS.jl, to configure
SQS and SNS to use GoAWS.

## Examples

Here we demonstrate using the config with a local server we launch
as a subprocess.

```julia
using GoAWS, AWS
@service SQS

server = GoAWS.Server()
aws_config = GoAWSConfig(server)
run(server; wait=false)

# ... now we can use the config:
SQS.create_queue("my_queue"; aws_config)

kill(server) # when you are done
```

One can also use a `GoAWSConfig` with a GoAWS server launched outside
of the Julia process. Simply set the `endpoint` and `region` using the
keyword argument constructor:

```julia
aws_config = GoAWSConfig(; endpoint="localhost:5203", region="us-east-1") 
# ... now we can use the config:
SQS.create_queue("my_queue"; aws_config)
```
"""
struct GoAWSConfig <: AWS.AbstractAWSConfig
    endpoint::URI
    region::String
end

function GoAWSConfig(; endpoint=DEFAULT_ADDRESS, region="us-east-2")
    return GoAWSConfig(server_uri(endpoint), region)
end

AWS.region(cfg::GoAWSConfig) = cfg.region
AWS.credentials(::GoAWSConfig) = AWSCredentials("", "", "", "")

function AWS.generate_service_url(cfg::GoAWSConfig, service::String, resource::String)
    service in ("sqs", "sns") ||
        throw(ArgumentError("GoAWS config only supports SQS and SNS service requests; got $service"))
    # NOTE: cannot use joinpath here, as it will silently truncate many resource strings
    return string(cfg.endpoint, resource)
end
