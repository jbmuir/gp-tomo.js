using Pkg
Pkg.activate(".")

using PlotlyJS
using Dash
using Random
using Distributions
using LinearAlgebra

if length(ARGS) >= 2
    compute_derivative = parse(Bool, ARGS[2])
else
    compute_derivative = false
end

if length(ARGS) >= 1 
    port = parse(Int, ARGS[1])
else
    port = 8081
end

# Functions for 1D squared exponential GPs: 
K(x, xₚ, ρ, l) = ρ^2 * exp(-(x-xₚ).^2 / (2*l^2)) # x should be column vector, xp should be row vector when vectorized
dK_dx(x, xₚ, ρ, l) = -(x-xₚ)*K(x, xₚ, ρ, l)/l^2
dK_dxₚ(x, xₚ, ρ, l) = K(x, xₚ, ρ, l)*(x-xₚ)/l^2
dK_dxdxₚ(x, xₚ, ρ, l) = K(x, xₚ, ρ,l)/l^2 - (x-xₚ)*K(x, xₚ, ρ, l)*(x-xₚ)/l^4

function app(port, compute_derivative, rseed=1)
    Random.seed!(rseed)
    npoints = 101
    σd = 0.3
    x = rand(Uniform(-1,1), npoints)
    freq = 5*π/2
    y = cos.(freq.*x) + σd.*randn(npoints)

    xₚ = -1:0.01:1

    function gp_prediction(ρ=1.0, l=1.0, σ=0.1; compute_derivative=false)
        # Kₓₓ = ρ^2 .* exp.(-(x.-x').^2 ./ (2*l^2)) K(x, x, ρ, σ, l)
        # Kₓₚₓ = ρ^2 .* exp.(-(xₚ.-x').^2 ./ (2*l^2)) K(x, x, ρ, σ, l)
        # Kₓₓₚ = ρ^2 .* exp.(-(x.-xₚ').^2 ./ (2*l^2)) K(x, x, ρ, σ, l)
        # Kₓₚₓₚ = ρ^2 .* exp.(-(xₚ.-xₚ').^2 ./ (2*l^2)) K(x, x, ρ, σ, l)
        Kₓₓ = K.(x, x', ρ, l)
        Kₓₚₓ = K.(xₚ, x', ρ, l)
        Kₓₓₚ = K.(x, xₚ', ρ, l)
        Kₓₚₓₚ = K.(xₚ, xₚ', ρ, l)
        K̂ = Kₓₓ + σ^2 * I
        mean_fₓₚ = Kₓₚₓ * (K̂ \ y) # for this demo, we assume a zero-mean GP
        std_fₓₚ = sqrt.(diag(Kₓₚₓₚ .- Kₓₚₓ * (K̂ \ Kₓₓₚ)))
        if compute_derivative
            dKₓₚₓ_dx = dK_dx.(xₚ, x', ρ, l)
            dKₓₓₚ_dxₚ = dK_dxₚ.(x, xₚ', ρ, l)
            dKₓₚₓₚ_dxdxₚ = dK_dxdxₚ.(xₚ, xₚ', ρ, l)
            mean_dfₓₚ = dKₓₚₓ_dx * (K̂ \ y)
            std_dfₓₚ = sqrt.(diag(dKₓₚₓₚ_dxdxₚ .- dKₓₚₓ_dx  * (K̂ \ dKₓₓₚ_dxₚ)))
            return (mean_fₓₚ, std_fₓₚ, mean_dfₓₚ, std_dfₓₚ)
        else
            return (mean_fₓₚ, std_fₓₚ)
        end
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
                    min = 0.01,
                    max = 0.5,
                    step = 0.01,
                    value = 0.5,
                    marks = Dict([i => ("$i") for i in [0.1, 0.2, 0.3, 0.4, 0.5]])
                ),

                html_div(id = "rho-val",
                style = Dict("margin-top" => "15px", "margin-left" => "15px", "margin-bottom" => "5px")),
                dcc_slider(
                    id = "rho-slider",
                    min = 0.01,
                    max = 2.5,
                    step = 0.01,
                    value = 1,
                    marks = Dict([i => ("$i") for i in [0.5, 1.0, 1.5, 2.0, 2.5]]),
                ),

                html_div(id = "l-val",
                style = Dict("margin-top" => "15px", "margin-left" => "15px", "margin-bottom" => "5px")),
                dcc_slider(
                    id = "l-slider",
                    min = 0.01,
                    max = 0.5,
                    step = 0.01,
                    value = 1,
                    marks = Dict([i => ("$i") for i in [0.1, 0.2, 0.3, 0.4, 0.5]])
                )
            end
        end
    end

    callback!(
        app,
        Output("sigma-val", "children"),
        Input("sigma-slider", "value")
    ) do sigma_val
        "Data noise σ: $(sigma_val)"
    end

    callback!(
        app,
        Output("rho-val", "children"),
        Input("rho-slider", "value")
    ) do rho_val
        "GP amplitude ρ: $(rho_val)"
    end

    callback!(
        app,
        Output("l-val", "children"),
        Input("l-slider", "value")
    ) do l_val
        "GP lengthscale l: $(l_val) m"
    end

    callback!(
        app,
        Output("graphic", "figure"),
        Input("sigma-slider", "value"),
        Input("rho-slider", "value"),
        Input("l-slider", "value")
    ) do σ, ρ, l
        if compute_derivative
            (mean_fₓₚ, std_fₓₚ, mean_dfₓₚ, std_dfₓₚ) = gp_prediction(ρ, l, σ; compute_derivative=true)
        else
            (mean_fₓₚ, std_fₓₚ) = gp_prediction(ρ, l, σ; compute_derivative=false)
        end

        ebar_yp = mean_fₓₚ.+std_fₓₚ
        ebar_ym = mean_fₓₚ.-std_fₓₚ
        gp_part = [                
            (x = xₚ,
             y = mean_fₓₚ,
             type = "line",
             name="mean",
             line=Dict("color"=>"#10DDDD", "width"=>4),
             hoverlabel = Dict("font" => Dict("family"=>"helvetica", "size" => 14))),
            (x = xₚ,
                y = ebar_yp,
                type = "line",
                line=Dict("color"=>"#10DDDD", "width"=>0),
                hoverlabel = Dict("font" => Dict("family"=>"helvetica", "size" => 14)),
                name="± 1 s.d.",
                showlegend=false
                ),
            (x = xₚ,
             y = ebar_ym,
             type = "line",
             fill="tonexty",
             line=Dict("color"=>"#10DDDD", "width"=>0),
             hoverlabel = Dict("name"=>"test", "font" => Dict("family"=>"helvetica", "size" => 14)),
             name="± 1 s.d.")
             ]
        
        if compute_derivative
            ebar_dyp = mean_dfₓₚ.+std_dfₓₚ
            ebar_dym = mean_dfₓₚ.-std_dfₓₚ
            gp_d_part = [(x = xₚ,
                         y = mean_dfₓₚ,
                         type = "line",
                         name="derv. mean",
                         line=Dict("color"=>"#FF79C6", "width"=>4),
                         hoverlabel = Dict("font" => Dict("family"=>"helvetica", "size" => 14))),
           (x = xₚ,
               y = ebar_dyp,
               type = "line",
               line=Dict("color"=>"#FF79C6", "width"=>0),
               hoverlabel = Dict("font" => Dict("family"=>"helvetica", "size" => 14, "extra"=>Dict("bgcolor"=>"rgba(0,0,0,0)"))),
               name="± 1 s.d.",
               showlegend=false
               ),
           (x = xₚ,
            y = ebar_dym,
            type = "line",
            fill="tonexty",
            line=Dict("color"=>"#FF79C6", "width"=>0),
            hoverlabel = Dict("name"=>"test", "font" => Dict("family"=>"helvetica", "size" => 14)),
            name="± 1 s.d.")]
            range = [max(-5,1.05*min(minimum(y), minimum(ebar_ym),minimum(ebar_dym))), min(5,1.05*max(maximum(y),maximum(ebar_yp),maximum(ebar_dyp)))]
        else
            gp_d_part = []
            range = [max(-4,1.05*min(minimum(y), minimum(ebar_ym))), min(4,1.05*max(maximum(y),maximum(ebar_yp)))]
        end

        datavec = vcat(
                (x=x,
                 y=y,
                 mode="markers",
                 name="data", 
                 marker=Dict("color"=>"#FFCC50", "size"=>10)),
                 gp_part,
                 gp_d_part)

        figure = (
            data = datavec,
            layout = (
                paper_bgcolor="rgba(0,0,0,0)",
                plot_bgcolor="rgba(0,0,0,0)",
                margin=Dict("l"=>50,"r"=>0,"b"=>50,"t"=>15),
                xaxis = Dict(
                    "title" => "X (arb.)",
                    "titlefont" => Dict(
                        "size" => 20,
                        "color" => "#FAFFFA",
                        "family" => "helvetica"
                    ),
                    "tickfont" => Dict(
                        "size" => 14,
                        "color" => "#FAFFFA",
                        "family" => "helvetica"
                    ),
                    "ticks" => "outside",
                    "tickcolor" => "#FAFFFA",
                    "ticklen" => 10
                ),
                yaxis = Dict(
                    "title" => "Y (arb.)",
                    "titlefont" => Dict(
                        "size" => 20,
                        "color" => "#FAFFFA",
                        "family" => "helvetica"
                    ),
                    "tickfont" => Dict(
                        "size" => 14,
                        "color" => "#FAFFFA",
                        "family" => "helvetica"
                    ),
                    "range" => range,
                    "ticks" => "outside",
                    "tickcolor" => "#FAFFFA",
                    "ticklen" => 10
                ),
                legend = Dict(
                    "font" => Dict("family"=>"helvetica", "color"=>"#FAFFFA")
                )
            )
        )
    end

    run_server(app, "0.0.0.0", port, debug=true)
end

app(port, compute_derivative)
 