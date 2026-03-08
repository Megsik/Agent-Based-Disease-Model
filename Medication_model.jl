function medication_step(agent::Agent)
    # Apply medication if the agent is not already medicated
    if !agent.under_treatment
        if (agent.status == :L_S || agent.status == :L_R) && rand() < LATENT_MEDICATION_SHARE
            agent.under_treatment = true
            agent.treatment_duration = 5
        elseif (agent.status == :I_S || agent.status == :I_R) && rand() < INFECTED_MEDICATION_SHARE
            agent.under_treatment = true
            agent.treatment_duration = 10
        end
    end
end