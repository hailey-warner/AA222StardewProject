using Plots

heatmap(1:28, 1:13, p;
    xlabel="Day Planted", ylabel="Crop",
    yticks=(1:13, String.(SPRING_CROPS)),
    title="Expected Profit (\$) by Crop and Planting Day",
    background_color = :transparent)
savefig("expected_profit_heatmap.png")

function policy_heatmap(policy::Matrix{Float64}; filename::String)
    heatmap(policy,
        xlabel = "Day of Season",
        ylabel = "Crop",
        title = "Optimal Crop Planting Policy",
        colorbar_title = "Crops Planted",
        xticks = 1:28,
        yticks=(1:13, String.(SPRING_CROPS)),
        size=(800,400),
        background_color = :transparent)
    savefig(filename)
end

function plot_gold_over_time(x::Matrix{Float64}; filename::String)
    gold = zeros(28)
    gold[1] = 500.0
    harvest_income = zeros(28)
    daily_costs = zeros(28)

    for i in 1:13, d in 1:28
        q = x[i, d]
        if q == 0
            continue
        end

        daily_costs[d] += q * PRICES[i]

        for dp in d+1:28
            if check_harvest(d, dp, DAYS_TO_GROW[i], DAYS_TO_REGROW[i])
                harvest_income[dp] += q * REVENUE[i]
            end
        end
    end

    # compute gold over time (costs on day d-1, harvests on day d)
    for d in 2:28
        gold[d] = gold[d-1] - daily_costs[d-1] + harvest_income[d]
    end
    gold[1] -= daily_costs[1]
    println("gold: ", gold)

    plot(1:28, gold, xlabel="Day", ylabel="Gold", title="Total Gold Over Season",
         lw=2, legend=false, background_color=:transparent, ylims=(0,4000))
    savefig(filename)
end