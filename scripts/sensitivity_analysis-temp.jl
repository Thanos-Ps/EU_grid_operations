# Script to perfrom sensitivity analysis in our system and examine parameters that affect economic benefits

# Question: Could we get info from lagrange multipliers of power models output?

# Import packages and create short names
import DataFrames; const _DF = DataFrames
import CSV
import JuMP
import Gurobi
import Feather
import PowerModels; const _PM = PowerModels
import JSON
using EU_grid_operations; const _EUGO = EU_grid_operations

# Select your favorite solver
solver = JuMP.optimizer_with_attributes(Gurobi.Optimizer, "OutputFlag" => 0)

using Plots


# Create a function that calculates the average value of the objective function over the simulated hours
function calculate_mean_obj!(result, t, number_of_clusters)
    # Calulate the number of simulated hours selected by the temporal sampling
    simulated_hours = length(t)*length(t[1])

    # Initialize variable to store the sum of the values
    objective_sum = 0.0

    # Loop over all hours for the final iteration
    for j in 1:number_of_clusters
        for hour in t[j]
            # Extract the objective value for each hour in the iteration
            objective_value = result["$hour"]["objective"]
            
            # Update the sum for calculating the mean later
            objective_sum += objective_value
        end

    end
    # Calculate the mean by dividing the total sum by the number of simulated hours
    mean_objective = objective_sum / simulated_hours

    return mean_objective
end

# Select the TYNDP version to be used:
# - 2020
# - 2024

# Select input paramters for:
# TYNDP 2020:
#  - Scenario selection: Distributed Energy (DE), National Trends (NT), Global Ambition (GA)
#  - Planning years: 2025 (NT only), 2030, 2040
#  - Climate year: 1982, 1984, 2007
#  - Number of hours: 1 - 8760
# TYNDP 2024:
#  - Scenario selection: Distributed Energy (DE), National Trends (NT), Global Ambition (GA)
#  -  Planning years: 2030, 2040, 2050
#  -  Climate year: 1995, 2008, 2009
#  -  Number of hours: 1 - 8760
# Fetch data: true/false, to parse input data (takes ~ 1 min.)

tyndp_version = "2020"
fetch_data = true
number_of_hours = 8760
scenario = "GA"
year = "2030"
climate_year = "2007"


# Load grid and scenario data
if fetch_data == true
    pv, wind_onshore, wind_offshore = _EUGO.load_res_data()
    ntcs, nodes, arcs, capacity, demand, gen_types, gen_costs, emission_factor, inertia_constants, node_positions = _EUGO.get_grid_data(tyndp_version, scenario, year, climate_year)
end


# Construct input data dictionary in PowerModels style 
input_data, nodal_data = _EUGO.construct_data_dictionary(tyndp_version, ntcs, arcs, capacity, nodes, demand, scenario, climate_year, gen_types, pv, wind_onshore, wind_offshore, gen_costs, emission_factor, inertia_constants, node_positions)

# Select dynamic rating parameters
prediction_horizon = 6                                           # Time horizon for the iterative solution that considers the admissible power
tolerance = 10^-1                                                # Acceptable tolerance of error for convergence

# Insert id of cables with dynamic rating
cable_id = [16, 92, 123]
converter_id = [120, 121, 127]

# Select temporal sampling parameters
sampling_type_flag = "clusters"                                  # Options: "clusters" or "rep_days"
# Case clusters:
number_of_clusters = 30
days_per_cluster = 1
# Case rep_days:
rep_days = []

# Perform temporal sampling of simulation horizon
include("../src/dynamic_cable_rating/temporal_sampling.jl")

if sampling_type_flag == "rep_days"
    number_of_clusters = length(rep_days)
    t, repetitions, number_of_iterations = temporal_sampling!(sampling_type_flag, rep_days, nothing)
elseif sampling_type_flag =="clusters"
    t, repetitions, number_of_iterations = temporal_sampling!(sampling_type_flag, number_of_clusters, days_per_cluster)
end

# Include the necessary scripts - functions 
include("../src/dynamic_cable_rating/thermal_model.jl")
include("../src/dynamic_cable_rating/construct_cable_dict.jl")
include("../src/dynamic_cable_rating/create_meshed_offshore_grid.jl")
include("run_zonal_tyndp_model-dynamic-2_5-sens.jl")
include("run_zonal_tyndp_model-modified_sens.jl")

# Select examined scenarios
examined_starting_temperatures = [20, 30, 40, 50, 60, 70, 80]                        # Cable temperature at the start of the simulation       


# Initialize arrays that will store results of objective function
# Each row represents a different ratio and each column represents a different cable rating.
objective_values = []
ref_objective_values = []
#objective_values = zeros(length(examined_ratios),length(examined_cable_ratings))
#ref_objective_values = zeros(length(examined_ratios),length(examined_cable_ratings))

# Initialize values for cable and converter capacities to create the meshed offshore grid
cable_capacity = 10
converter_capacity = 15
create_meshed_offshore_grid!(input_data,cable_capacity,converter_capacity)


for temp in examined_starting_temperatures
    
    local starting_temperature = temp

    # Run examined dynamic rating case
    local result_dyn = simulate_dynamic_case!(input_data, nodal_data, cable_data, cable_id, t, number_of_clusters, number_of_iterations, prediction_horizon, starting_temperature, tolerance, error)

    # Calcualate and store the value of the objective function
    local mean_objective = calculate_mean_obj!(result_dyn, t, number_of_clusters)
    append!(objective_values, mean_objective)
    #objective_values[j[1],i[1]] = mean_objective

    # Reset cable_id and converter_id capacities for reference case
    for cable in cable_id
        input_data["branch"]["$cable"]["rate_a"] = cable_capacity
        input_data["branch"]["$cable"]["rate_p"] = cable_capacity
        input_data["branch"]["$cable"]["rate_i"] = cable_capacity
    end

    for converter in converter_id
        
        if converter == 127
            # Case UK converter (it needs double the capacity)
            input_data["branch"]["$converter"]["rate_a"] = 2*converter_capacity
            input_data["branch"]["$converter"]["rate_p"] = 2*converter_capacity
            input_data["branch"]["$converter"]["rate_i"] = 2*converter_capacity
        else
            # Case BE, NL converters 
            input_data["branch"]["$converter"]["rate_a"] = converter_capacity
            input_data["branch"]["$converter"]["rate_p"] = converter_capacity
            input_data["branch"]["$converter"]["rate_i"] = converter_capacity
        end

    end    

    # Run the examined refernce case
    local result_ref = simulate_reference_case!(input_data, nodal_data, cable_data, cable_id, t, number_of_clusters, number_of_iterations, prediction_horizon, starting_temperature)
    # Calcualate and store the value of the objective function
    local ref_mean_objective = calculate_mean_obj!(result_ref, t, number_of_clusters)
    append!(ref_objective_values, ref_mean_objective)   
    #ref_objective_values[j[1],i[1]] = ref_mean_objective
end

# Compare reference with dynamic case to evaluate economic benefit
economic_benefit = 100*(ref_objective_values .- objective_values)./ref_objective_values

plot(examined_starting_temperatures, economic_benefit, xlabel=" Initial cable temperature [degC]", ylabel = "Average Economic Benefit per Hour [%]", 
label = "$(cable_capacity/10) GW cable, $(converter_capacity/10) GW converter",size=(800, 600), linewidth=2, xlabelfontsize=14,   # Bigger x-axis label font
ylabelfontsize=14,   # Bigger y-axis label font
titlefontsize=18,    # Bigger title font
tickfontsize=12,
legendfontsize = 12)     # Bigger tick labels )


