using GoAWS
using Test
using AWS
using Aqua

@service SQS use_response_type = true

@testset "Aqua" begin
    Aqua.test_all(GoAWS; ambiguities=false)
end

@testset "GoAWS.jl" begin
    @testset "Server" begin
        server = GoAWS.Server(; address="localhost:4103")
        @test sprint(show, server) == "GoAWS.Server(\"http://localhost:4103\", unstarted)"

        @test_throws ErrorException kill(server)
        @test_throws ErrorException process_running(server)
        @test_throws ErrorException process_exited(server)
        @test_throws ErrorException getpid(server)
        @test isnothing(server.config_path)
        run(server; wait=false)
        try
            @test getpid(server) isa Number
            @test process_running(server)
            @test !isnothing(server.config_path)
            # While the port is occupied, test we can load another server on another port
            server2 = GoAWS.Server(; address="localhost:4104")
            run(server2; wait=false)
            sleep(1) # let it startup before we kill it, so we get a 0 exitcode
            kill(server2)
            sleep(1)
            @test server2.process.exitcode == 0
        finally
            sleep(1) # let it startup before we kill it, so we get a 0 exitcode
            kill(server)
            sleep(1)
        end
        @test process_exited(server)
        @test server.process.exitcode == 0
        @test isnothing(server.config_path)
    end

    @testset "with_go_aws" begin
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
