using GoAWS
using Test
using AWS
@service SQS use_response_type = true

@testset "GoAWS.jl" begin
    @testset begin
        with_go_aws() do aws_config
            result = parse(SQS.create_queue("my_queue"; aws_config))
            queue_url = result["CreateQueueResult"]["QueueUrl"]
        
            ret = parse(SQS.send_message("hello", queue_url; aws_config))
            id = ret["SendMessageResult"]["MessageId"] # looks like a UUID, but isn't documented to be one, so guess we should leave it as a string
        
            messages = parse(SQS.receive_message(queue_url, Dict("WaitTimeSeconds" => 1); aws_config))
        
            @test messages["ReceiveMessageResult"]["Message"]["Body"] == "hello"
            receipt = messages["ReceiveMessageResult"]["Message"]["ReceiptHandle"]
            @test startswith(receipt, id)
            SQS.delete_message(queue_url, receipt; aws_config)
        
            SQS.delete_queue(queue_url; aws_config)
        end

    end
end
