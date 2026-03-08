

using CSV, DataFrames, Random, Statistics, BlackBoxOptim, Dates

# ---------- Loading file ---------- #
tb_outcomes_path = raw"C:/Users/Dell/Downloads/TB_burden_countries_2025-11-26.csv"
country = "India"
year_target = 2023

# Choose fitting phase: 1 = fit Beta only (fast),
# 2 = fit Beta + LATENT_TRANSITION_RATE + RECOVERY_RATE + MORTALITY_RATE (slower)
const FITTING_PHASE = 1

# Optimization settings (increase for final runs)
REPLICATES_PER_EVAL = 3     # increase for estimates to be stable
OPTIMIZE_MAXSTEPS = 200          # increase to make outcomes fit better 
OPTIMIZE_POPSIZE  = 12

# Monte-Carlo validation after fitting
MonteCarlo_REPLICATES = 20      # increase for stable outcomes

# ---------- Include model files ----------
include("parameters.jl")    
include("Define_agents.jl")
include("contact_pattern.jl")
include("Latent_progression.jl")
include("Disease_progression.jl")
include("Medication_model.jl")
include("Collect_stats.jl")
include("main_revised.jl")   

# ---------- Helper: load WHO file ----------
function safe_read(path)
    isfile(path) || error("WHO file not found: $path")
    df = CSV.read(path, DataFrame)
    println("WHO file loaded: ", path, " (", nrow(df), " rows, cols: ", join(names(df), ", "), ")")
    return df
end

out_df = safe_read(tb_outcomes_path)

# ---------- Helper: fuzzy column finder ( to save time) ----------
function find_col(df::DataFrame, patterns::Vector{String})
    for p in patterns
        for nm in names(df)
            if occursin(lowercase(p), lowercase(String(nm)))
                return Symbol(nm)
            end
        end
    end
    return nothing
end

#col_country = find_col(out_df, ["country","entity","location"])
#col_year    = find_col(out_df, ["year"])
#col_inc_num = find_col(out_df, ["incidence","inc_num","incidence_number","e_inc_num"])
#col_mort_num= find_col(out_df, ["mortality","mort_num","e_mort_num","deaths"])
#col_fatality = find_col(out_df, ["fatality","cfr","case_fatality"])
#col_pop = find_col(out_df, ["population","pop"])

col_country = find_col(out_df, ["country"])
col_year    = find_col(out_df, ["year"])
col_inc_num = find_col(out_df, ["e_inc_num"])
col_mort_num= find_col(out_df, ["e_mort_num"])
col_fatality = find_col(out_df, ["cfr"])
col_pop = find_col(out_df, ["e_pop_num"])
println("Detected columns -> country: $col_country, year: $col_year, incidence: $col_inc_num, mortality: $col_mort_num, fatality: $col_fatality, population: $col_pop")

# ---------- Pick WHO targets ----------
function pick(df, ccol, ycol, country, year, col)
    if col === nothing return nothing end
    rows = df[(df[!, ccol] .== country) .&& (df[!, ycol] .== year), :]
    return nrow(rows) == 0 ? nothing : rows[1, col]
end

inc_num  = pick(out_df, col_country, col_year, country, year_target, col_inc_num)
mort_num = pick(out_df, col_country, col_year, country, year_target, col_mort_num)
fatality = pick(out_df, col_country, col_year, country, year_target, col_fatality)
population = pick(out_df, col_country, col_year, country, year_target, col_pop)

inc_100k = (inc_num !== nothing && population !== nothing) ? (inc_num / population) * 100_000 : nothing
mort_100k= (mort_num !== nothing && population !== nothing) ? (mort_num / population) * 100_000 : nothing
println("WHO targets (",country," ",year_target,") -> incidence/100k: ", inc_100k, " mortality/100k: ", mort_100k, " fatality: ", fatality)

# ---------- Stats -> metrics (for better interpretation) ----------
function stats_to_metrics(statistics::simStats)

    total_new_cases = sum(statistics.new_cases)
    total_tb_deaths = sum(statistics.tb_deaths)

    years = SIMULATION_YEARS - 1   
    pop = POP_SIZE

    inc_per100k = (total_new_cases / (pop * years)) * 100000
    mort_per100k = (total_tb_deaths / (pop * years)) * 100000

    cfr = total_new_cases == 0 ? 0.0 : total_tb_deaths / total_new_cases
    #uncomment below only while debugging
    #println("DEBUG → cases=", total_new_cases,
    #        " deaths=", total_tb_deaths,
    #        " pop=", pop,
    #        " years=", years)

    return (inc_per100k=inc_per100k, mort_per100k=mort_per100k, cfr=cfr)

end
# ---------- Plausible per-day soft-targets and penalty helper ----------
function annual_to_daily(a)
    return 1 - (1 - a)^(1/365)
end

# Example plausible annual ranges ( adjustable)
plausible = Dict(
    :latent_transition_annual => (0.01, 0.10),   
    :recovery_annual => (0.5, 0.9),              
    :mortality_annual => (0.005, 0.12),          
    :relapse_annual => (0.01, 0.05)              
)

plausible_day = Dict(k => (annual_to_daily(v[1]), annual_to_daily(v[2])) for (k,v) in plausible)

println("Plausible per-day ranges:")
for (k,v) in plausible_day
    println(" ", k, " => ", v)
end

# ---------- Build bounds depending on FITTING_PHASE ----------
if FITTING_PHASE == 1
    # Phase 1: fit Beta only (fast)
    param_names = ["Beta"] 
    lower_bounds = [0.1]
    upper_bounds = [0.5]
elseif FITTING_PHASE == 2
    # Phase 2: fit Beta + latent + recovery + mortality
    param_names = ["Beta", "LATENT_TRANSITION_RATE", "RECOVERY_RATE", "MORTALITY_RATE"]
    lower_bounds = [0.5, annual_to_daily(0.01), 1/150, annual_to_daily(0.01)]
    upper_bounds = [50.0, annual_to_daily(0.2), 1/90, annual_to_daily(0.06)]

else
    error("Unsupported FITTING_PHASE: $FITTING_PHASE. Use 1 or 2.")
end

search_ranges = [(lower_bounds[i], upper_bounds[i]) for i in 1:length(lower_bounds)]
println("Fitting parameters: ", param_names)
println("Using search ranges: ", search_ranges)

# ---------- Soft penalty to discourage edge/implausible params ----------
function soft_penalty(params)
    pen = 0.0
    for i in 1:length(params)
        lo, hi = search_ranges[i]
        p = params[i]
        range = hi - lo
        if p < lo
            pen += ((lo - p)/ (range + 1e-12))^2 * 1e6
        elseif p > hi
            pen += ((p - hi)/ (range + 1e-12))^2 * 1e6
        else
            margin = min(p - lo, hi - p)
            if margin < 0.05*range
                pen += (0.05*range - margin)/ (0.05*range) * 1.0
            end
        end
    end
    return pen
end

# ---------- Weighted Normalized Least Squares Objective ---------- #

function compute_normalizers(inc_100k, mort_100k, fatality)
    # incidence
    alpha_I = (inc_100k === nothing) ? 1.0 : max(abs(inc_100k), 1e-6)

    # mortality
    alpha_M = (mort_100k === nothing) ? 1.0 : max(abs(mort_100k), 1e-6)

    # CFR
    if fatality === nothing
        alpha_C = 1.0
    else
        target_cfr = fatality > 1 ? fatality/100 : fatality
        alpha_C = max(abs(target_cfr), 1e-4)   
    end

    return alpha_I, alpha_M, alpha_C
end


# for updating paramters , getting normalising scales, running replicates and computing errors
function stochastic_objective(params; replicates=REPLICATES_PER_EVAL)
    
    if FITTING_PHASE == 1
        global Beta = params[1]
    else
        Beta_new, LATENT_TRANSITION_RATE_new, RECOVERY_RATE_new, MORTALITY_RATE_new = params
        global Beta = Beta_new
        global LATENT_TRANSITION_RATE = LATENT_TRANSITION_RATE_new
        global RECOVERY_RATE = RECOVERY_RATE_new
        global MORTALITY_RATE = MORTALITY_RATE_new
    end

    
    alpha_I, alpha_M, alpha_C = compute_normalizers(inc_100k, mort_100k, fatality)

    
    errs = Float64[]

    for r in 1:replicates
        agents, statistics = initialize_model()
        invokelatest(run_simulation!, agents, statistics)
        metrics = stats_to_metrics(statistics)

        e = 0.0

        # normalized incidence error
        if inc_100k !== nothing
            residI = (metrics.inc_per100k - inc_100k) / alpha_I
            e += residI^2
        end

        # normalized mortality error
        if mort_100k !== nothing
            residM = (metrics.mort_per100k - mort_100k) / alpha_M
            e += residM^2
        end

        # normalized CFR error 
        if fatality !== nothing
            target_cfr = fatality > 1 ? fatality/100 : fatality
            residC = (metrics.cfr - target_cfr) / alpha_C
            e += residC^2
        end

        push!(errs, e)
    end

    
    return mean(errs) + soft_penalty(params)
end

# ---------- Run optimizer ----------
println("Starting optimization ... (this may take time)")
res = bboptimize(
    p -> stochastic_objective(p; replicates=REPLICATES_PER_EVAL),
    SearchRange = search_ranges,
    Method = :adaptive_de_rand_1_bin,
    MaxSteps = OPTIMIZE_MAXSTEPS,
    PopulationSize = OPTIMIZE_POPSIZE
)

best = best_candidate(res)
println("Best candidate (per-day): ", best)
println("Fitness: ", best_fitness(res))

# ---------- Save calibrated parameters ----------
cal_file = "calibrated_parameters.jl"
open(cal_file, "w") do io
    println(io, "# calibrated parameters written on $(Dates.now())")
    for (i,name) in enumerate(param_names)
        println(io, "$(name) = $(best[i])")
    end
end
println("Wrote calibrated parameters to: ", cal_file)

# ---------- Monte-Carlo validation ----------
# ----------------------------
# Monte-Carlo Validation (per-population metrics)
# ----------------------------

println("Running Monte-Carlo validation with $MonteCarlo_REPLICATES replicates ...")

# Arrays to store results
incs = Float64[]
morts = Float64[]
cfrs = Float64[]

for i in 1:MonteCarlo_REPLICATES
    # Initialize agents and stats
    agents, statistics = initialize_model()
    
    # Run simulation
    invokelatest(run_simulation!, agents, statistics)
    
    # Compute metrics per-population
    metrics = stats_to_metrics(statistics)   
    
    # Store metrics
    push!(incs, metrics.inc_per100k)
    push!(morts, metrics.mort_per100k)
    push!(cfrs, metrics.cfr)
end

# Summarize MC results
println("Incidence per100k: mean=$(mean(incs)), 95%CI=(", quantile(incs, 0.025), ",", quantile(incs, 0.975), "), WHO=", inc_100k)
println("Mortality per100k: mean=$(mean(morts)), 95%CI=(", quantile(morts, 0.025), ",", quantile(morts, 0.975), "), WHO=", mort_100k)
println("CFR: mean=$(mean(cfrs)), 95%CI=(", quantile(cfrs, 0.025), ",", quantile(cfrs, 0.975), "), WHO=", fatality)

# Save MC results to CSV
val_df = DataFrame(incidence_per100k = incs, mortality_per100k = morts, cfr = cfrs)
CSV.write("calibration_validation_results.csv", val_df)
println("Saved MC validation results to calibration_validation_results.csv")