# GoAWS

[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://beacon-biosignals.github.io/GoAWS.jl/dev/)
[![Build Status](https://github.com/beacon-biosignals/GoAWS.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/beacon-biosignals/GoAWS.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/beacon-biosignals/GoAWS.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/beacon-biosignals/GoAWS.jl)
![Code Style: YASGuide](https://img.shields.io/badge/code%20style-yas-violet.svg)(https://github.com/jrevels/YASGuide)

Provides a Julia interface to [goaws](https://github.com/Admiral-Piett/goaws), which provides a local clone of AWS SQS and SNS.
See the [goaws](https://github.com/Admiral-Piett/goaws) readme for what is supported and what is not.

## Example

```julia
using AWS, GoAWS
@service SQS use_response_type = true

with_go_aws() do aws_config
    result = parse(SQS.create_queue("my_queue"; aws_config))
    queue_url = result["CreateQueueResult"]["QueueUrl"]

    ret = parse(SQS.send_message("hello", queue_url; aws_config))
    id = ret["SendMessageResult"]["MessageId"]

    messages = parse(SQS.receive_message(queue_url, Dict("WaitTimeSeconds" => 1); aws_config))

    @test messages["ReceiveMessageResult"]["Message"]["Body"] == "hello"
    receipt = messages["ReceiveMessageResult"]["Message"]["ReceiptHandle"]
    @test startswith(receipt, id)
    SQS.delete_message(queue_url, receipt; aws_config)

    SQS.delete_queue(queue_url; aws_config)
end
```
