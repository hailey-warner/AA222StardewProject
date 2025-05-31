include("simulator.jl")
include("plotting.jl")

using Random
using Statistics

function random_policy()
    x = zeros(Float64, 13, 28)
    gold = zeros(Float64, 28)
    daily_costs = zeros(Float64, 28)
    income = zeros(Float64, 28)
    plots_used = zeros(Int, 28)

    gold[1] = 500

    for d in 1:28
        for i in shuffle(1:13) # randomize crop order

            # check plot occupancy
            occ_days = Int[]
            for dp in d+1:28
                if occupied(d, dp, DAYS_TO_GROW[i], DAYS_TO_REGROW[i])
                    push!(occ_days, dp)
                end
            end
            if isempty(occ_days)
                continue
            end

            max_affordable = PRICES[i] == 0 ? P : floor(Int, gold[d] / PRICES[i])
            max_land = minimum(P .- plots_used[occ_days])
            max_plant = min(max_affordable, max(0, max_land))

            # can't plant anything today
            if max_plant == 0
                continue
            end

            q = rand(0:max_plant)
            if q == 0 # planting none of crop i
                continue
            end

            x[i, d] = q
            gold[d] -= q * PRICES[i]
            for day in occ_days
                plots_used[day] += q
                if check_harvest(d, day, DAYS_TO_GROW[i], DAYS_TO_REGROW[i])
                    income[day] += q * REVENUE[i]
                end
            end

        end

        if d < 28
            gold[d+1] = gold[d] + income[d+1]
        end

        daily_costs[d] = sum(x[:, d] .* PRICES)
    end

    return x, income
end

# for testing:
# policy, income = random_policy()
# policy_heatmap(policy, filename="random_heatmap.png")
# plot_gold_over_time(policy, filename="random_gold_over_time.png")
# println("random policy: ", policy)
# println("gold over season: ", income)

# for simulating --> summary statistics

function final_gold_from_policy(x::Matrix{Float64})
    n, D = size(x)
    gold = zeros(D)
    gold[1] = 500.0
    harvest_income = zeros(D)
    daily_costs = zeros(D)

    for i in 1:n, d in 1:D
        q = x[i, d]
        if q == 0
            continue
        end
        daily_costs[d] += q * PRICES[i]
        for dp in d+1:D
            if check_harvest(d, dp, DAYS_TO_GROW[i], DAYS_TO_REGROW[i])
                harvest_income[dp] += q * REVENUE[i]
            end
        end
    end

    for d in 2:D
        gold[d] = gold[d-1] - daily_costs[d-1] + harvest_income[d]
    end
    gold[1] -= daily_costs[1]
    return gold[end]
end

nsims = 1000
final_gold_vals = Float64[]

for sim in 1:nsims
    policy, _ = random_policy()
    push!(final_gold_vals, final_gold_from_policy(policy))
end

println("Mean final gold (plot) over ", nsims, " sims: ", mean(final_gold_vals))
println("Standard deviation: ", std(final_gold_vals))