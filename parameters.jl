
############### GLOBAL MODEL PARAMETERS #################

# ----------------
# Simulation controls & scaling
# ----------------
POP_SIZE = 1000                 # calibration population but must be larger than this for realistic outcomes
SIMULATION_YEARS = 2            # must be large enough to see realistic outcomes 
STEPS_PER_YEAR = 365
GRID_SIZE = (80, 80)             # spatial interactions grid
INIT_INF_SHARE = 0.02          # 2% infections at start

# ----------------
# Contact structure
# ----------------
TOTAL_CONTACTS = 10       
LOCAL_CONTACT_FRACTION = 0.65    
LOCAL_CONTACT_RADIUS = 10
GLOBAL_CONTACT_FRACTION = 1 - LOCAL_CONTACT_FRACTION
CONTACT_OTHERS = TOTAL_CONTACTS
DRUG_RESISTANCE_CONTACT_PROB = 0.1
REINFECTION_PROBABILITY = 0.01

# ----------------
# Transmission
# ----------------
Beta = 0.03          # Transmission prob              
p_resistance = 0.1

# ----------------
# Natural / disease mortality (per-day)
# ----------------
NATURAL_DEATH_RATE = 1 - (1 - 0.01)^(1/365)  
MORTALITY_RATE = 1 - (1 - 0.11)^(1/365)     
MORTALITY_RATE_RESIST = 1 - (1 - 0.15)^(1/365)           

# ----------------
# Progression & recovery (per-day)
# ----------------
LATENT_TRANSITION_RATE = 1 - (1 - 0.05)^(1/365)  
LATENT_TRANSITION_RATE_RESIST = 1 - (1 - 0.05)^(1/365)
RECOVERY_RATE = 1/180.0                       
RECOVERY_RATE_RESIST = 1/240.0            

# ----------------
# Medication & other rates
# ----------------
DRUG_RESISTANCE_PROB = 0.02
LATENT_MEDICATION_SHARE = 0.6
INFECTED_MEDICATION_SHARE = 0.8
RELAPSE_RATE = 1 - (1 - 0.03)^(1/365)        
RETURN_TO_SUSCEPTIBLE_RATE = 0.1

RELAPSE_RATE_DRL = 0.1
RELAPSE_RATE_DSL = 0.05
NEW_TREATMENT_SUCCESS_DRL = 0.60
NEW_TREATMENT_SUCCESS_DSL = 0.85

# ----------------
# I/O & debug flags
# ----------------
SAVE_DATA = false
VERBOSE_SIM = false

# ----------------
# Convenience constants computed from above
# ----------------
LOCAL_CONTACTS = round(Int, TOTAL_CONTACTS * LOCAL_CONTACT_FRACTION)
GLOBAL_CONTACTS = TOTAL_CONTACTS - LOCAL_CONTACTS