# Import packages and create short names
import DataFrames; const _DF = DataFrames
import CSV
import JuMP
import Gurobi
import Feather
import PowerModels; const _PM = PowerModels
import JSON
using EU_grid_operations; const _EUGO = EU_grid_operations
using DCROPF

function generate_temperature_array()
  # Total hours in a year
  total_hours = 8760
  # Days in a year (1 to 365)
  days = 1:365
  # Daily temperature values using a cosine function
  amplitude = 5.0
  vertical_shift = 13.0
  peak_day = 258  # Mid-September (day 258)
  T_day = amplitude .* cos.(2π/365 .* (days .- peak_day)) .+ vertical_shift
  # Expand daily values to hourly (repeat each value 24 times)
  T_hourly = repeat(T_day, inner=24)
  # Ensure the length matches 8760 hours
  @assert length(T_hourly) == total_hours
  return T_hourly
end

# Generate the temperature array
temperature_array = generate_temperature_array()
#T_amb = 18
#temperature_array = T_amb*ones(8760)
# Optional: Visualize the first week (24*7 = 168 hours)
#plot(temperature_array, xlabel="Hour", ylabel="Temperature (°C)", label="Hourly Temperature")


# Select your favorite solver
solver = JuMP.optimizer_with_attributes(Gurobi.Optimizer, "OutputFlag" => 0)


# Select the TYNDP version to be used:
tyndp_version = "2024"
fetch_data = true
number_of_hours = 8760

if tyndp_version == "2020"
  scenario = "DE"
  year = "2040"
  climate_year = "2007"

elseif tyndp_version == "2024"
  scenario = "GA"
  year = "2050"
  climate_year = "2009"
end

# Load grid and scenario data
if fetch_data == true
    pv, wind_onshore, wind_offshore = _EUGO.load_res_data()
    ntcs, nodes, arcs, capacity, demand, gen_types, gen_costs, emission_factor, inertia_constants, node_positions = _EUGO.get_grid_data(tyndp_version, scenario, year, climate_year)
end

# Construct input data dictionary in PowerModels style 
if tyndp_version == "2020"
  scenario_id = "$scenario$year"
elseif tyndp_version == "2024"
  scenario_id = "scenario"
end

input_data, nodal_data = _EUGO.construct_data_dictionary(tyndp_version, ntcs, arcs, capacity, nodes, demand, scenario_id, climate_year, gen_types, pv, wind_onshore, wind_offshore, gen_costs, emission_factor, inertia_constants, node_positions)


# Select Dynamic Cable Rating parameters
Tmax = 90                                                 # [degC], Temperature limit of the cables 
T0 = 80                                                   # [degC], Initial temperature of the cables 
prediction_horizon = 24*7                                   # [hours], For the optimization problem 
time_elapsed = 3600                                       # [s], Time step of the simulation        
time_constant = 27*3600                                    # [s], Thermal time constant of the cables   
#temp_to_pow_ratio = 0.9                                   #[degC/%], parameter of the thermal model
temp_to_pow_ratio = 0.72                                  # modified such that the steady state temperature is 90 degC, at T_amb = 18 degC. (Could be set for the worst case scenario of T_amb = 25 degC)
constraint_relax_factor = 10                              # [-], Factor to relax the constraints for the power limit of the dcr cables
#T_amb = 18                                                # [degC], Ambient temperature of the cables (the subsea temperature)

# Create a dictionary that contains the DCR parameters
dcr_data = Dict{String, Any}(
  "Tmax" => Tmax,
  "T0" => T0,
  "prediction_horizon" => prediction_horizon, 
  "time_elapsed" => time_elapsed, 
  "time_constant" => time_constant, 
  "temp_to_pow_ratio" => temp_to_pow_ratio,
  "constraint_relax_factor" => constraint_relax_factor,
  "temperature_array" => temperature_array
  )

# Select the temporal sampling method and parameters
sampling_type_flag = "period"                           # Options: "clusters" or "rep_days"  or "period"
number_of_clusters = 12
days_per_cluster = 7
#rep_days = collect(1:10:365)
rep_days = 1
initial_day = 1
period_duration_days = 30

# Define capacities of branches in offshore grid in p.u. with base value 100 MVA
cable_capacity = 10
converter_capacity = 25     

# Include necessary scripts for functions, initializations and other operations
include("../src/dynamic_cable_rating/create_meshed_offshore_grid.jl")
include("../src/dynamic_cable_rating/temporal_sampling.jl")

# Modify the input_data dictionary to add the offshore grid and extract the cable_id vector
cable_id = create_meshed_offshore_grid!(input_data,cable_capacity,converter_capacity, tyndp_version)

# Make copy of input data dictionary as RES and demand data updated for each hour (and also include the created offhsore grid)
input_data_raw = deepcopy(input_data)

# Perform the temporal sampling based on the selected option
# Note: The temporal sampling function works only for number_of_hours = 8760.
if sampling_type_flag == "rep_days"
  number_of_clusters = length(rep_days)
  t, repetitions = temporal_sampling!(sampling_type_flag, prediction_horizon, rep_days, nothing)
elseif sampling_type_flag =="clusters"
  t, repetitions = temporal_sampling!(sampling_type_flag, prediction_horizon, number_of_clusters, days_per_cluster)
elseif sampling_type_flag == "period"
  number_of_clusters = 1
  t, repetitions = temporal_sampling!(sampling_type_flag, prediction_horizon, initial_day, period_duration_days)
end

# Calculate the total number of repetitions to cover the whole simulation horizon 
final_reps_total = number_of_clusters*length(repetitions[1])

include("simulate_case.jl")

# Run the dynamic case
result = simulate_case!(input_data, nodal_data, solver, prediction_horizon, number_of_clusters, repetitions, cable_id, dcr_data)

# Select no cables with DCR to simulate the reference case (DCR OFF)
cable_id = []

# Run the reference case
result_ref = simulate_case!(input_data_raw, nodal_data, solver, prediction_horizon, number_of_clusters, repetitions, cable_id, dcr_data)

#Function to calculate the economic benefit
function calculate_mean_obj(result,final_reps_total, prediction_horizon)
    mean_obj = 0

    for reps_total in 1:final_reps_total
            mean_obj += result["$reps_total"]["objective"]   # cost per prediction horizon duration (e.g. 24h = 1 day)
    end
    mean_obj = mean_obj/(final_reps_total*prediction_horizon) # cost per hour
    return mean_obj
end 

cost_ref = calculate_mean_obj(result_ref,final_reps_total, prediction_horizon)
cost_dcr = calculate_mean_obj(result,final_reps_total, prediction_horizon)

economic_benefit = cost_ref - cost_dcr
economic_benefit_in_perc = (economic_benefit/cost_ref)*100

println("The economic benefit of DCR is: $economic_benefit EUR/h")
println("The economic benefit of DCR is: $economic_benefit_in_perc %")

