include("simulator.jl")
include("plotting.jl")

using JuMP
using GLPK

# x[i, d] = number of crops i planted on day d
model = Model(GLPK.Optimizer)
@variable(model, x[1:13, 1:28] >= 0, Int) # design variable
@variable(model, gold[1:28] >= 0, Int) # auxillary variable

# profit maximization
@objective(model, Max, sum(x[i, d] * p[i, d] for i in 1:13, d in 1:28))

# budget (start with 500 gold)
@constraint(model, gold[1] == 500 - sum(PRICES[i] * x[i,1] for i in 1:13))
for d in 2:28
    @constraint(model,
        gold[d] == gold[d-1] +
                   sum(x[i, dp] * REVENUE[i]
                       for i in 1:13, dp in 1:(d-1)
                       if check_harvest(dp, d, DAYS_TO_GROW[i], DAYS_TO_REGROW[i])) -
                   sum(PRICES[i] * x[i,d] for i in 1:13)
    )
end

# strawberries not available until day 13
for d in 1:12
    @constraint(model, x[13, d] == 0)
end

# land use
for dp in 1:28
    @constraint(model,
        sum(x[i, d] for i in 1:13, d in 1:dp if occupied(d, dp, DAYS_TO_GROW[i], DAYS_TO_REGROW[i])) <= P
    )
end

optimize!(model)
objective_value(model)

println(value.(x))
policy_heatmap(value.(x), filename="policy_heatmap.png")
plot_gold_over_time(value.(x), filename="policy_gold_over_time.png")