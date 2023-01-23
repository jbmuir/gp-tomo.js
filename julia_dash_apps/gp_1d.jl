using Pkg
Pkg.activate(".")

using PlotlyJS
using Dash
using Random
using Distributions
using LinearAlgebra

if length(ARGS) >= 1 
    port = parse(Int, ARGS[1])
else
    port = 8081
end

function app(port, rseed=1)
    Random.seed!(rseed)
    npoints = 101
    σd = 0.3
    x = rand(Uniform(-(π/2),(π/2)), npoints)
    y = cos.(5.0.*x) + σd.*randn(npoints)

    xₚ = -(π/2):0.01:(π/2)

    function gp_prediction(ρ=1.0, l=1.0, σ=0.1)
        Kₓₓ = ρ^2 .* exp.(-(x.-x').^2 ./ (2*l^2))
        Kₓₚₓ = ρ^2 .* exp.(-(xₚ.-x').^2 ./ (2*l^2))
        Kₓₓₚ = ρ^2 .* exp.(-(x.-xₚ').^2 ./ (2*l^2))
        Kₓₚₓₚ = ρ^2 .* exp.(-(xₚ.-xₚ').^2 ./ (2*l^2))
        K̂ = Kₓₓ + σ^2 * I
        mean_fₓ = Kₓₚₓ * (K̂ \ y) # for this demo, we assume a zero-mean GP
        std_fₓ = sqrt.(diag(Kₓₚₓₚ .- Kₓₚₓ * (K̂ \ Kₓₓₚ)))
        return (mean_fₓ, std_fₓ)
    end

    app = dash(external_stylesheets = ["/assets/app.css"])
    app.title = ""
    app.layout = html_div() do
        html_div(className = "row") do
            html_div(className = "nine columns",
                dcc_graph(
                id = "graphic",
                animate = true,
                )
            ),

            html_div(style = Dict("border" => "0.5px solid", "border-radius" => 5, "margin-top" => 68), className = "three columns") do

                html_div(id = "sigma-val",
                style = Dict("margin-top" => "15px", "margin-left" => "15px", "margin-bottom" => "5px")),
                dcc_slider(
                    id = "sigma-slider",
                    min = 0,
                    max = 0.5,
                    step = 0.01,
                    value = 0.5,
                    marks = Dict([i => ("$i") for i in [0, 0.1, 0.2, 0.3, 0.4, 0.5]])
                ),

                html_div(id = "rho-val",
                style = Dict("margin-top" => "15px", "margin-left" => "15px", "margin-bottom" => "5px")),
                dcc_slider(
                    id = "rho-slider",
                    min = 0,
                    max = 2,
                    step = 0.01,
                    value = 1,
                    marks = Dict([i => ("$i") for i in [0, 0.5, 1.0, 1.5, 2.0]])
                ),

                html_div(id = "l-val",
                style = Dict("margin-top" => "15px", "margin-left" => "15px", "margin-bottom" => "5px")),
                dcc_slider(
                    id = "l-slider",
                    min = 0,
                    max = 2,
                    step = 0.01,
                    value = 1,
                    marks = Dict([i => ("$i") for i in [0, 0.5, 1.0, 1.5, 2.0]])
                )
            end
        end
    end

    callback!(
        app,
        Output("sigma-val", "children"),
        Input("sigma-slider", "value")
    ) do sigma_val
        "Data noise σ : $(sigma_val)"
    end

    callback!(
        app,
        Output("rho-val", "children"),
        Input("rho-slider", "value")
    ) do rho_val
        "GP amplitude ρ : $(rho_val)"
    end

    callback!(
        app,
        Output("l-val", "children"),
        Input("l-slider", "value")
    ) do l_val
        "GP lengthscale : $(l_val) m"
    end

    callback!(
        app,
        Output("graphic", "figure"),
        Input("sigma-slider", "value"),
        Input("rho-slider", "value"),
        Input("l-slider", "value")
    ) do σ, ρ, l
        (mean_fₓ, std_fₓ) = gp_prediction(ρ, l, σ)
        ebar_yp = mean_fₓ.+std_fₓ
        ebar_ym = mean_fₓ.-std_fₓ
        figure = (
            data = [
                (x=x,
                 y=y,
                 mode="markers",
                 name="data", 
                 marker=Dict("color"=>"grey", "size"=>10)),
                (x = xₚ,
                 y = mean_fₓ,
                 type = "line",
                 name="mean",
                 line=Dict("color"=>"rgb(139,0,139)", "width"=>4),
                 hoverlabel = Dict("font" => Dict("size" => 14))),
                (x = xₚ,
                 y = ebar_yp,
                 type = "line",
                 line=Dict("color"=>"rgb(139,0,139)", "width"=>0),
                 showlegend=false
                 ),
                (x = xₚ,
                 y = ebar_ym,
                 type = "line",
                 fill="tonexty",
                 line=Dict("color"=>"rgb(139,0,139)", "width"=>0),
                 name="± 1 σ")
            ],
            layout =(
                paper_bgcolor="rgba(0,0,0,0)",
                plot_bgcolor="rgba(0,0,0,0)",
                xaxis = Dict(
                    "title" => "X (arb.)",
                    "titlefont" => Dict(
                        "size" => 20
                    ),
                    "tickfont" => Dict(
                        "size" => 14
                    ),
                ),
                yaxis = Dict(
                    "title" => "Y (arb.)",
                    "titlefont" => Dict(
                        "size" => 20,
                        "color" => "white"
                    ),
                    "tickfont" => Dict(
                        "size" => 14,
                        "color" => "white"
                    ),
                    "range" => [1.05*min(minimum(y), minimum(ebar_ym)), 1.05*max(maximum(y),maximum(ebar_yp))],
                    "ticks" => "outside",
                    "tickcolor" => "white",
                    "ticklen" => 10
                ),
            )
        )
    end

    run_server(app, "0.0.0.0", port, debug=true)
end

app(port)
 