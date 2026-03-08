# Agent-Based-Disease-Model

This repository contains a simple agent-based model (ABM) for simulating the spread of an infectious disease in a population. The model represents individuals as agents and simulates disease transmission through spatial contacts between nearby agents. Agents transition between epidemiological states such as Susceptible, Latent, Infectious, Recovered, and Dead. Transmission occurs through interactions with neighboring agents within a defined contact radius, creating localized patterns of infection spread. The model is implemented in Julia and was developed to explore agent-based approaches to epidemiological modeling. 

Dataset- 
For parameter estimation , WHO TB burden data for India in 2023 was taken from the official WHO website. 

Model Features-
Agent based disease transmission
Spacial contact network
Disease progression and recovery
Parameter calibration for transmission rate, latent transmission rate, revovery rate and mortality
Simulation of incidence and mortality results (using MonteCarlo)

While running the model- parameter_estimation.jl estimates the parameters and after that main_revised.jl could be run for final results.

Future Improvements-
Age-structured population
Improved parameters calibration
Larger population size
Visulatisations 
Expanded for other diseases and countries

Development notes- 
This project was made as a learning exercise. During development, online resources and AI tools were occacianally used to resolve programming issues.




