# =============================
# main_simulation.jl 
# =============================
include("parameters.jl")   # Load parameters first making sure they are available for the model component files 

using CSV
using DataFrames
using StatsBase
using Random

# ----------------------------
# Include Model Components
# ----------------------------
include("Define_agents.jl")        
include("contact_pattern.jl")      
include("Initial_infections.jl")    
include("Latent_progression.jl")   
include("Disease_progression.jl")  
include("medication_model.jl")           
include("Collect_stats.jl")

const USE_PRECOMPUTED_NETWORK = true

# ----------------------------
# Initialize infections
# ----------------------------
function initialize_infections!(agents, INIT_INF_SHARE)
    num_initial_infected = round(Int, INIT_INF_SHARE * length(agents))
    infected_indices = randperm(length(agents))[1:num_initial_infected]

    for i in infected_indices
        agents[i].status = rand([:I_S, :I_R])
        agents[i].time_infected = 0
        agents[i].newly_infected = true  
    end
    #uncomment next line only for debugging 
    #println("Number of initially infected:", num_initial_infected)
end

# ----------------------------
# Model Initialization
# ----------------------------
function initialize_model()
    # Create agents
    agents = create_agents(POP_SIZE, GRID_SIZE, TOTAL_CONTACTS)
    
    # Initialize infections
    initialize_infections!(agents, INIT_INF_SHARE)
    
    total_steps = (SIMULATION_YEARS - 1) * STEPS_PER_YEAR  # after burn-in

    stats = simStats(
    zeros(Int, total_steps),
    zeros(Int, total_steps),
    zeros(Int, total_steps),
    zeros(Int, total_steps),
    zeros(Int, total_steps),
    zeros(Int, total_steps),
    zeros(Int, total_steps),
    zeros(Int, total_steps),
    zeros(Int, total_steps),
    zeros(Int, total_steps)
  )


    
    # Precompute local network if needed
    if USE_PRECOMPUTED_NETWORK
        global local_network = building_local_network(agents, LOCAL_CONTACT_RADIUS)
    else
        global local_network = nothing
    end

    return agents, stats
end
agents, stats = initialize_model()
# ----------------------------
# Simulation Loop
# ----------------------------
function run_simulation!(agents, stats; verbose=false)
    burnin_steps = STEPS_PER_YEAR
    total_steps = SIMULATION_YEARS * STEPS_PER_YEAR

    for step in 1:total_steps
        infection_step_all!(agents, local_network, step)
        for agent in agents
            #contacts = fetch_contacts(agent, agents, local_network)
            #infection_step!(agent, agents, local_network)
            disease_progression(agent)
            latent_progression(agent)
            medication_step(agent)
        end

        if step > burnin_steps
            collect_stats(step - burnin_steps, agents, stats)
        end
        
         #println("Step:", step,
         #" S:", count(a->a.status == :S, agents),
         #" L:", count(a->a.status in [:L_S,:L_R], agents),
         #" I:", count(a->a.status in [:I_S,:I_R], agents))
    end
   
end


# ----------------------------
function stats_to_dataframe(stats::simStats)
    DataFrame(
        susceptible = stats.susceptible,
        infected = stats.infected,
        latent = stats.latent,
        medicated_infected = stats.medicated_infected,
        medicated_latent = stats.medicated_latent,
        recovered = stats.recovered,
        dead = stats.dead,
        new_cases = stats.new_cases,
        new_deaths = stats.new_deaths,
        tb_deaths = stats.tb_deaths
    )
end


# ----------------------------
# Main
# ----------------------------
function main()
    agents, statistics = initialize_model()
    run_simulation!(agents, statistics)
end
#run_simulation!(agents, stats)
# Run the simulation by uncommenting only after parameter estimation 
#main()
if abspath(PROGRAM_FILE) == @__FILE__

    @time begin
        agents, statistics = initialize_model()
        run_simulation!(agents, statistics)
    end

    println("Done timing")

end

