```@meta
CurrentModule = GoAWS
```

# GoAWS

Documentation for [GoAWS](https://github.com/ericphanson/GoAWS.jl).

```@index
```

## Configuration

To configure the server, pass `config`. It is suggested to modify the default config, for example:
```
config = GoAWS.default_config()
config["Local"]["LogToFile"] = true
server = Server(; config)
# or `with_go_aws(; config) do ....`
```

To see what configuration options are available, see the example config in the GoAWS source:
<https://github.com/Admiral-Piett/goaws/blob/v0.4.5/app/conf/goaws.yaml>.

## Troubleshooting steps

* Create the server with `verbose=true` to print messages to `stdout`/`stderr`.
* Call `run` with `wait=false` to error if the process errors.
* Do not pass floating-point values as the timeout for `SQS.change_message_visibility` with AWS.jl. Those are [required to be integers by AWS](https://docs.aws.amazon.com/AWSSimpleQueueService/latest/APIReference/API_ChangeMessageVisibility.html) and GoAWS in particular seems to handle them poorly (go panics without a clear error message).

## API documentation

```@autodocs
Modules = [GoAWS]
```
