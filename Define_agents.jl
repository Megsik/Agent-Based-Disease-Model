########################################################
###### Define_agents.jl  ######
########################################################

# ----------------------------
# Agent struct
# ----------------------------
mutable struct Agent
    id::Int
    status::Symbol             # :S, :I_S, :I_R, :L_S, :L_R, :R, :D
    time_infected::Int         # Number of days infected
    under_treatment::Bool     # Whether agent is on treatment
    contact_others::Int        # Number of contacts per day
    contact_status::Symbol     # :S, :I, etc. (optional)
    drug_resistance::Bool      # True if drug-resistant infection
    treatment_duration::Int   # Days remaining on treatment
    position::Tuple{Int, Int}  # 2D grid coordinates (x, y)
    newly_infected::Bool       # Track if agent became infected this timestep
    newly_dead::Bool
    tb_deaths::Bool           # Track if agent died this timestep
end

# ----------------------------
# Function to create agents
# ----------------------------
function create_agents(POP_SIZE::Int, GRID_SIZE::Tuple{Int,Int}, TOTAL_CONTACTS::Int)
    agents = Agent[]
    for i in 1:POP_SIZE
        push!(agents, Agent(
            i,                        # id
            :S,                       # status: susceptible
            0,                        # time_infected
            false,                    # under_treatment
            TOTAL_CONTACTS,           # contact_others
            :S,                       # contact_status
            false,                    # drug_resistance
            0,                        # treatment_duration
            (rand(1:GRID_SIZE[1]), rand(1:GRID_SIZE[2])), # random position
            false,                    # newly_infected
            false,                    # newly_dead
            false                     # tb_deaths
        ))
    end
    return agents
end