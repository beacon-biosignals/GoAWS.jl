using GoAWS
using Documenter

DocMeta.setdocmeta!(GoAWS, :DocTestSetup, :(using GoAWS); recursive=true)

makedocs(;
         modules=[GoAWS],
         authors="Beacon Biosignals, Inc.",
         repo=Remotes.GitHub("beacon-biosignals", "GoAWS.jl"),
         sitename="GoAWS.jl",
         format=Documenter.HTML(;
                                prettyurls=get(ENV, "CI", "false") == "true",
                                canonical="https://beacon-biosignals.github.io/GoAWS.jl",
                                edit_link="main",
                                assets=String[],),
         pages=["Home" => "index.md"],)

deploydocs(;
           repo="github.com/beacon-biosignals/GoAWS.jl.git",
           devbranch="main",
           push_preview=true,)
