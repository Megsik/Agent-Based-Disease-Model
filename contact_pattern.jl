# ============================
# Contact Pattern
# ============================

# ----------------------------------------
# Build Local Network Function
# ----------------------------------------
function building_local_network(agents, LOCAL_CONTACT_RADIUS)
    N = length(agents)
    local_network = Vector{Vector{Int}}(undef, N)  

    for i in 1:N
        neighbors = Int[]
        pos_i = agents[i].position

        for j in 1:N
            if i != j
                pos_j = agents[j].position
                dist = sqrt((pos_i[1] - pos_j[1])^2 + (pos_i[2] - pos_j[2])^2)
                if dist <= LOCAL_CONTACT_RADIUS
                    push!(neighbors, j)
                end
            end
        end

        local_network[i] = neighbors
    end

    return local_network
end

# ----------------------------------------
# Fetch Contacts 
# ----------------------------------------
function fetch_contacts(agent, agents, local_network; TOTAL_CONTACTS=10) # total contacts were fixed here for simplicity
    contacts = Int[]

    # -------- Local contacts ----------
    local_ids = local_network[agent.id]
    n_local = min(length(local_ids), TOTAL_CONTACTS ÷ 2)  
    if n_local > 0
        append!(contacts, sample(local_ids, n_local, replace=false))
    end

    # -------- Global contacts ----------
    n_global = TOTAL_CONTACTS - length(contacts)
    global_pool = setdiff(1:length(agents), [agent.id; contacts])
    if !isempty(global_pool) && n_global > 0
        append!(contacts, sample(global_pool, min(n_global, length(global_pool)), replace=false))
    end

    return contacts
end

