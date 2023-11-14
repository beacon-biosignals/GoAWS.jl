struct GoAWSConfig <: AWS.AbstractAWSConfig
    endpoint::URI
    region::String
end

GoAWSConfig(; endpoint=DEFAULT_ADDRESS, region="us-east-2") = GoAWSConfig(endpoint, region)

AWS.region(cfg::GoAWSConfig) = cfg.region
AWS.credentials(::GoAWSConfig) = AWSCredentials("", "", "", "")

function AWS.generate_service_url(cfg::GoAWSConfig, service::String, resource::String)
    service in ("sqs", "sns") || throw(ArgumentError("GoAWS config only supports SQS and SNS service requests; got $service"))
    # NOTE: cannot use joinpath here, as it will silently truncate many resource strings
    string(cfg.endpoint, resource)
end
