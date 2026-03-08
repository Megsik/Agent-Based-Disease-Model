function disease_progression(agent::Agent)

    # Natural death
    if rand() < NATURAL_DEATH_RATE
        agent.status = :D
        agent.newly_dead = true
        agent.tb_deaths = false
        return
    end

    if agent.status == :I_S

        r = rand()

        if r < MORTALITY_RATE
            agent.status = :D
            agent.newly_dead = true
            agent.tb_deaths = true

        elseif r < MORTALITY_RATE + LATENT_TRANSITION_RATE
            agent.status = :L_S

        elseif r < MORTALITY_RATE + LATENT_TRANSITION_RATE + RECOVERY_RATE
            agent.status = :R

        elseif r < MORTALITY_RATE + LATENT_TRANSITION_RATE + RECOVERY_RATE + DRUG_RESISTANCE_PROB
            agent.status = :I_R
            agent.drug_resistance = true
        end

    elseif agent.status == :I_R

        r = rand()

        if r < MORTALITY_RATE_RESIST
            agent.status = :D
            agent.newly_dead = true
            agent.tb_deaths = true

        elseif r < MORTALITY_RATE_RESIST + LATENT_TRANSITION_RATE_RESIST
            agent.status = :L_R

        elseif r < MORTALITY_RATE_RESIST + LATENT_TRANSITION_RATE_RESIST + RECOVERY_RATE_RESIST
            agent.status = :R
        end

    elseif agent.status == :R

        if rand() < REINFECTION_PROBABILITY
            agent.status = :S
        end

    end
end