using GoAWS
using Documenter

DocMeta.setdocmeta!(GoAWS, :DocTestSetup, :(using GoAWS); recursive=true)

makedocs(;
    modules=[GoAWS],
    authors="Beacon Biosignals, Inc.",
    repo="https://github.com/ericphanson/GoAWS.jl/blob/{commit}{path}#{line}",
    sitename="GoAWS.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://ericphanson.github.io/GoAWS.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/ericphanson/GoAWS.jl",
    devbranch="main",
)
