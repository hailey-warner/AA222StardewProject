using DataFrames
using Distributions
using StatsPlots

P = 10
EXPECTED_REV = 1.12 # (assuming farming level = 1, fertilizer level = 1)

SPRING_CROPS = [:blue_jazz,
                :cauliflower,
                :garlic,
                :kale,
                :parsnip,
                :potato,
                :rhubarb,
                :tulip,
                :unmilled_rice,
                :carrot,
                :coffee_bean,
                :green_bean,
                :strawberry]

PRICES = [30, 80, 40, 70, 20, 50, 100, 20, 40, 0, 2500, 60, 100]

REVENUE = [50, 175, 60, 110, 35, 80, 220, 30, 30, 35, 60, 40, 120]

DAYS_TO_GROW = [4, 12, 4, 6, 4, 6, 13, 6, 6, 3, 10, 10, 8]

DAYS_TO_REGROW = [Inf, Inf, Inf, Inf, Inf, Inf, Inf, Inf, Inf, Inf, 2, 3, 4]

df = DataFrame(crop = SPRING_CROPS,
               price = PRICES,
               revenue = REVENUE,
               days_to_grow = DAYS_TO_GROW,
               days_to_regrow = DAYS_TO_REGROW)
println(df)

function get_crop_profit(cost, base_revenue, farming_level, fertilizer_level)

    p_gold    = 0.01 + 0.02*farming_level + 0.2*fertilizer_level*(farming_level+2)/12
    p_silver  = 2*p_gold
    p_iridium = 0.5*p_gold
    p_normal  = 1 - p_gold - p_silver - p_iridium

    p = [p_normal, p_silver, p_gold, p_iridium]
    multipliers = [1.0, 1.25, 1.5, 2.0]

    expected_revenue =  base_revenue*multipliers[rand(Categorical(p))]
    return expected_revenue - cost
end

function num_harvests(G::Int, R::Float64, d::Int) # number of harvests if planted on day d
    first_harvest_day = d + G
    if first_harvest_day > 28
        return 0
    elseif isinf(R)
        return 1
    else
        return 1 + floor(Int, (28 - first_harvest_day) / R)
    end
end

function occupied(d, dp, G, R)
    if isinf(R)
        return (d <= dp) && (dp < d + G)
    else
        return (d <= dp) && (dp <= 28)
    end
end

function check_harvest(d, dp, G, R)
    if isinf(R)
        return dp == d + G
    else
        harvest = d + G
        return dp ≥ harvest && (dp - harvest) % R == 0
    end
end

# expected profit table p[i, d]
p = zeros(Float64, 13, 28)
for i in 1:13
    G = DAYS_TO_GROW[i]
    R = DAYS_TO_REGROW[i]
    cost = PRICES[i]
    base_rev = REVENUE[i]
    exp_rev = base_rev * EXPECTED_REV

    for d in 1:28
        h = num_harvests(G, R, d)
        p[i,d] = h > 0 ? h * exp_rev - cost : -cost
    end
end