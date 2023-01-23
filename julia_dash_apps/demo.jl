using Pkg
Pkg.activate(".")

using PlotlyJS
using Dash

if length(ARGS) >= 1 
    port = parse(Int, ARGS[1])
else
    port = 8081
end

function app(port)
    t = 0.:1e-3:2.

    function response(f₀ = 10., ξ = 0.01, x₀ = 1., v₀ = 1.)
        ω₀ = 2π*f₀     # Natural angular frequency
        if 0. ≤ ξ < 1. # Undamped/Under-damped response
        Ω₀ = ω₀*√(1. - ξ^2)
        x = (x₀*cos.(Ω₀*t) + (v₀ + ξ*ω₀*x₀)*sin.(Ω₀*t)/Ω₀).*exp.(-ξ*ω₀*t)
        elseif ξ == 1.  # Critically damped response
        x = @. (x₀ + ω₀*x₀*t + v₀*t)*exp(-ω₀*t)
        else # Over-damped response
        β = ω₀*√(ξ^2 - 1.)
        x = @. (x₀*cosh(β*t) + (v₀ + ξ*ω₀*x₀*sinh(β*t))/β)*exp(-ξ*ω₀*t)
        end
    end

    function damping(value)
        if value == 1
            return 0.
        elseif value == 2
            return 0.001
        elseif value == 3
            return 0.01
        elseif value == 4
            return 0.1
        elseif value == 5
            return 1.
        else
            return 1.5
        end
    end

    app = dash(external_stylesheets = ["/assets/app.css"])
    app.title = ""
    app.layout = html_div() do
        html_h1("Free response of a mass-spring system", style = Dict("margin-top" => 50)),

        html_div(className = "row") do
            html_div(className = "nine columns",
                dcc_graph(
                id = "graphic",
                animate = true,
                )
            ),

            html_div(style = Dict("border" => "0.5px solid", "border-radius" => 5, "margin-top" => 68), className = "three columns") do
                html_div(id = "freq-val",
                style = Dict("margin-top" => "15px", "margin-left" => "15px", "margin-bottom" => "5px")),
                dcc_slider(
                    id = "freq-slider",
                    min = 1.,
                    max = 50.,
                    step = 1,
                    value = 10.,
                    marks = Dict([i => ("$i") for i in [1, 10, 20, 30, 40, 50]])
                ),

                html_div(id = "damp-val",
                style = Dict("margin-top" => "15px", "margin-left" => "15px", "margin-bottom" => "5px")),
                dcc_slider(
                    id = "damp-slider",
                    min = 1,
                    max = 6,
                    step = nothing,
                    value = 1,
                    marks = Dict([i => ("$(damping(i))") for i in 1:6])
                ),

                html_div(id = "disp-val",
                style = Dict("margin-top" => "15px", "margin-left" => "15px", "margin-bottom" => "5px")),
                dcc_slider(
                    id = "disp-slider",
                    min = -1.,
                    max = 1.,
                    step = 0.1,
                    value = 0.5,
                    marks = Dict([i => ("$i") for i in [-1, 0, 1]])
                ),

                html_div(id = "vel-val",
                style = Dict("margin-top" => "15px", "margin-left" => "15px",  "margin-bottom" => "5px")),
                dcc_slider(
                    id = "vel-slider",
                    min = -100.,
                    max = 100.,
                    step = 1.,
                    value = 0.,
                    marks = Dict([i => ("$i") for i in [-100, -50, 0, 50, 100]])
                )
            end
        end
    end

    callback!(
        app,
        Output("freq-val", "children"),
        Input("freq-slider", "value")
    ) do freq_val
        "Resonance frequency : $(freq_val) Hz"
    end

    callback!(
        app,
        Output("damp-val", "children"),
        Input("damp-slider", "value")
    ) do damp_val
        "Damping ratio : $(damping(damp_val))"
    end

    callback!(
        app,
        Output("disp-val", "children"),
        Input("disp-slider", "value")
    ) do disp_val
        "Initial displacement : $(disp_val) m"
    end

    callback!(
        app,
        Output("vel-val", "children"),
        Input("vel-slider", "value")
    ) do vit_val
        "Initial velocity : $(vit_val) m/s"
    end

    callback!(
        app,
        Output("graphic", "figure"),
        Input("freq-slider", "value"),
        Input("damp-slider", "value"),
        Input("disp-slider", "value"),
        Input("vel-slider", "value")
    ) do f₀, ξ, x₀, v₀
        rep = response(f₀, damping(ξ), x₀, v₀)
        figure = (
            data = [(
                x = t,
                y = rep,
                type = "line",
                hoverlabel = Dict(
                    "font" => Dict(
                        "size" => 14
                    )
                )
                )
            ],
            layout =(
                xaxis = Dict(
                    "title" => "Time (s)",
                    "titlefont" => Dict(
                        "size" => 20
                    ),
                    "tickfont" => Dict(
                        "size" => 14
                    ),
                ),
                yaxis = Dict(
                    "title" => "Displacement (m)",
                    "titlefont" => Dict(
                        "size" => 20
                    ),
                    "tickfont" => Dict(
                        "size" => 14
                    ),
                    "range" => [minimum(rep), maximum(rep)],
                    "ticks" => "outside",
                    "tickcolor" => "white",
                    "ticklen" => 10
                ),
            )
        )
    end

    run_server(app, "0.0.0.0", port)
end

app(port)
  