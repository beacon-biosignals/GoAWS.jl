using GoAWS
using Test
using AWS
using Aqua
using URIs

@service SQS use_response_type = true

@testset "Aqua" begin
    Aqua.test_all(GoAWS; ambiguities=false)
end

port = 41231
@testset "GoAWS.jl" begin
    @testset "Server" begin
        server = GoAWS.Server(; address="localhost:$port")
        @test sprint(show, server) == "GoAWS.Server(\"http://localhost:$port\", unstarted)"

        config = GoAWSConfig(server) # test constructing config from server object
        @test config.endpoint == server.address
        @test config.region == server.region

        @test_throws ErrorException kill(server)
        @test_throws ErrorException process_running(server)
        @test_throws ErrorException process_exited(server)
        @test_throws ErrorException getpid(server)
        @test isnothing(server.config_path)
        run(server; wait=false)
        sleep(0.5)
        try
            @test sprint(show, server) ==
                  "GoAWS.Server(\"http://localhost:$port\", running)"
            @test getpid(server) isa Number
            @test process_running(server)
            @test !isnothing(server.config_path)
            # While the port is occupied, test we can load another server on another port
            server2 = GoAWS.Server(; address="localhost:$(port+1)")
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
        @test sprint(show, server) ==
              "GoAWS.Server(\"http://localhost:$port\", exited successfully)"
        @test process_exited(server)
        @test server.process.exitcode == 0
        @test isnothing(server.config_path)
    end

    @testset "with_go_aws" begin
        with_go_aws() do aws_config
            parsed = parse(SQS.create_queue("my_queue"; aws_config))
            queue_url = parsed["QueueUrl"]

            parsed = parse(SQS.send_message("hello", queue_url; aws_config))
            id = parsed["MessageId"] # looks like a UUID, but isn't documented to be one, so guess we should leave it as a string

            parsed = parse(SQS.receive_message(queue_url, Dict("WaitTimeSeconds" => 1);
                                                 aws_config))
            @test length(parsed["Messages"]) == 1

            message = first(parsed["Messages"])
            @test message["Body"] == "hello"
            @test startswith(message["ReceiptHandle"], id)
            SQS.delete_message(queue_url, message["ReceiptHandle"]; aws_config)

            return SQS.delete_queue(queue_url; aws_config)
        end
    end

    @testset "GoAWSConfig" begin
        # Can pass strings
        cfg = GoAWSConfig(; endpoint="localhost:40912")
        @test cfg.endpoint == URI("http://localhost:40912")
    end
end
