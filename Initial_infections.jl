# --- Infection step for a single agent ---
function infection_step!(agent::Agent, agents::Vector{Agent}, local_network::Vector{Vector{Int}})
    newly_infected_count = 0
    contacts = fetch_contacts(agent, agents, local_network)
    #contacts = local_network[agent.id]
    # uncomment below only when debugging is required 
    #if agent.id ≤ 10
    #   n_contacts = length(contacts)
       # Print only first 10 contacts for readability
    #   first_contacts = contacts[1:min(n_contacts, 10)]
       #println("Agent ", agent.id, " has ", n_contacts, " contacts, first 10: ", first_contacts)
    #end

    # Only infectious agents transmit
    if agent.status in [:I_S, :I_R] && !agent.under_treatment
        

        
        

        for cid in contacts
            contact = agents[cid]

            # Only susceptible agents can be infected
            if contact.status == :S && !contact.newly_infected
                if rand() < Beta
                    # Assign latent type
                    contact.status = rand() < p_resistance ? :L_R : :L_S
                    contact.drug_resistance = contact.status == :L_R
                    contact.newly_infected = true
                    contact.tb_deaths = false
                    newly_infected_count += 1
                end
            end
        end
    end

    return newly_infected_count
end

# --- Wrapper for a full step ---
function infection_step_all!(agents::Vector{Agent}, local_network::Vector{Vector{Int}}, step::Int)
    total_new_infections = 0
    for agent in agents
        total_new_infections += infection_step!(agent, agents, local_network)
    end
    #println("Step $step: new infections = $total_new_infections")
end