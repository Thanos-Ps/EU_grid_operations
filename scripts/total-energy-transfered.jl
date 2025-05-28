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


# Calculation of average cable temperature
function calculate_new_temperature!(power, temperature, time_constant = 27*3600, temp_to_pow_ratio = 0.72, temperature_reference = 13, time_step = 3600)
  
    temperature_new = temperature + (abs(power)*temp_to_pow_ratio - (temperature - temperature_reference))*(time_step/time_constant)

    return temperature_new
  
end  

function compute_temperature_profile(power_vector;
    initial_temperature = 80.0,
    time_constant = 27*3600,
    temp_to_pow_ratio = 0.72,
    temperature_reference = 13,
    time_step = 3600)

    n = length(power_vector)
    temperature_vector = Vector{Float64}(undef, n)

    # Set the initial condition
    temperature_vector[1] = calculate_new_temperature!(
        power_vector[1],
        initial_temperature,
        time_constant,
        temp_to_pow_ratio,
        temperature_reference,
        time_step
    )

    # Iteratively compute the rest
    for t in 2:n
        temperature_vector[t] = calculate_new_temperature!(
            power_vector[t-1],
            temperature_vector[t-1],
            time_constant,
            temp_to_pow_ratio,
            temperature_reference,
            time_step
        )
    end

    return temperature_vector
end

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
sampling_type_flag = "clusters"                           # Options: "clusters" or "rep_days"  or "period"
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
#cable_id = []

# Run the reference case
result_ref = simulate_case!(input_data_raw, nodal_data, solver, prediction_horizon, number_of_clusters, repetitions, [], dcr_data)


######################## Post processing of results ####################################

# Initialize DataFrame to store results
results_df = _DF.DataFrame(
    hour = Float64[],
    pf_be_uk_dcr = Float64[],
    pf_nl_uk_dcr = Float64[],
    pf_be_nl_dcr = Float64[],
    total_power_dcr = Float64[],
    T_be_uk_dcr = Float64[],
    T_nl_uk_dcr = Float64[],
    T_be_nl_dcr = Float64[],
    pf_be_uk_no_dcr = Float64[],
    pf_nl_uk_no_dcr = Float64[],
    pf_be_nl_no_dcr = Float64[],
    total_power_no_dcr = Float64[]
)
# Initialize counters
reps_total = [0]
hour = [0]

for j in 1:number_of_clusters  
  for i in repetitions[j]            
    reps_total[1] += 1
    for network_hour in 1:prediction_horizon
      hour[1] = i + network_hour - 1
      # Results are in p.u. with base value 100 MVA
      # Extract the power flow values for the three cables when DCR is applied
      pf_be_uk_dcr = result["$(reps_total[1])"]["solution"]["nw"]["$network_hour"]["branch"]["$(cable_id[1])"]["pf"]
      pf_nl_uk_dcr = result["$(reps_total[1])"]["solution"]["nw"]["$network_hour"]["branch"]["$(cable_id[2])"]["pf"]
      pf_be_nl_dcr = result["$(reps_total[1])"]["solution"]["nw"]["$network_hour"]["branch"]["$(cable_id[3])"]["pf"]

      total_power_dcr = abs(pf_be_uk_dcr) + abs(pf_nl_uk_dcr) + abs(pf_be_nl_dcr)

      T_be_uk_dcr = result["$(reps_total[1])"]["solution"]["nw"]["$network_hour"]["branch"]["$(cable_id[1])"]["Temperature"]
      T_nl_uk_dcr = result["$(reps_total[1])"]["solution"]["nw"]["$network_hour"]["branch"]["$(cable_id[2])"]["Temperature"]
      T_be_nl_dcr = result["$(reps_total[1])"]["solution"]["nw"]["$network_hour"]["branch"]["$(cable_id[3])"]["Temperature"]

      pf_be_uk_no_dcr = result_ref["$(reps_total[1])"]["solution"]["nw"]["$network_hour"]["branch"]["$(cable_id[1])"]["pf"]
      pf_nl_uk_no_dcr = result_ref["$(reps_total[1])"]["solution"]["nw"]["$network_hour"]["branch"]["$(cable_id[2])"]["pf"]
      pf_be_nl_no_dcr = result_ref["$(reps_total[1])"]["solution"]["nw"]["$network_hour"]["branch"]["$(cable_id[3])"]["pf"]

      total_power_no_dcr = abs(pf_be_uk_no_dcr) + abs(pf_nl_uk_no_dcr) + abs(pf_be_nl_no_dcr)


      # Append the values to the DataFrame
      push!(results_df.hour, hour[1])
      push!(results_df.pf_be_uk_dcr, pf_be_uk_dcr)
      push!(results_df.pf_nl_uk_dcr, pf_nl_uk_dcr)
      push!(results_df.pf_be_nl_dcr, pf_be_nl_dcr)
      push!(results_df.total_power_dcr, total_power_dcr)
      push!(results_df.T_be_uk_dcr, T_be_uk_dcr)
      push!(results_df.T_nl_uk_dcr, T_nl_uk_dcr)
      push!(results_df.T_be_nl_dcr, T_be_nl_dcr)

      push!(results_df.pf_be_uk_no_dcr, pf_be_uk_no_dcr)
      push!(results_df.pf_nl_uk_no_dcr, pf_nl_uk_no_dcr)
      push!(results_df.pf_be_nl_no_dcr, pf_be_nl_no_dcr)
      push!(results_df.total_power_no_dcr, total_power_no_dcr)

    end
  end
end


# Calculate total cable utilization (of all 3 cables)
total_cable_utilization_dcr = sum(results_df.total_power_dcr)*100           # Convert to MWh 
total_cable_utilization_no_dcr = sum(results_df.total_power_no_dcr)*100 

# Calculate total cable utilization of BE-UK
total_cable_utilization_be_uk_dcr = sum(abs.(results_df.pf_be_uk_dcr))*100           # Convert to MWh 
total_cable_utilization_be_uk_no_dcr = sum(abs.(results_df.pf_be_uk_no_dcr))*100 


# Calculate total cable utilization of NL-UK
total_cable_utilization_nl_uk_dcr = sum(abs.(results_df.pf_nl_uk_dcr))*100           # Convert to MWh 
total_cable_utilization_nl_uk_no_dcr = sum(abs.(results_df.pf_nl_uk_no_dcr))*100 

# Calculate total cable utilization of BE-NL
total_cable_utilization_be_nl_dcr = sum(abs.(results_df.pf_be_nl_dcr))*100           # Convert to MWh 
total_cable_utilization_be_nl_no_dcr = sum(abs.(results_df.pf_be_nl_no_dcr))*100 

# Print the results
println("Total cable utilization with DCR: $total_cable_utilization_dcr MWh")
println("Total cable utilization without DCR: $total_cable_utilization_no_dcr MWh")
println("Total cable utilization BE-UK with DCR: $total_cable_utilization_be_uk_dcr MWh")
println("Total cable utilization BE-UK without DCR: $total_cable_utilization_be_uk_no_dcr MWh")
println("Total cable utilization NL-UK with DCR: $total_cable_utilization_nl_uk_dcr MWh")
println("Total cable utilization NL-UK without DCR: $total_cable_utilization_nl_uk_no_dcr MWh")
println("Total cable utilization BE-NL with DCR: $total_cable_utilization_be_nl_dcr MWh")
println("Total cable utilization BE-NL without DCR: $total_cable_utilization_be_nl_no_dcr MWh")


# Cacluate percentage of difference
percentage_difference = (total_cable_utilization_dcr - total_cable_utilization_no_dcr) / total_cable_utilization_no_dcr * 100
println("Percentage difference in cable utilization: $percentage_difference%")


# Calculate the average temperature of each cable with DCR and without DCR

# Convert power flows in absolut values and as a percentage of static Rating
abs_pf_be_uk_no_dcr = 100*abs.(results_df.pf_be_uk_no_dcr)/ input_data["branch"]["$(cable_id[1])"]["rate_a"]  # Convert to MWh
temp_profile_be_uk_no_dcr = compute_temperature_profile(abs_pf_be_uk_no_dcr)

abs_pf_nl_uk_no_dcr = 100*abs.(results_df.pf_nl_uk_no_dcr)/ input_data["branch"]["$(cable_id[2])"]["rate_a"]  # Convert to MWh
temp_profile_nl_uk_no_dcr = compute_temperature_profile(abs_pf_nl_uk_no_dcr)

abs_pf_be_nl_no_dcr = 100*abs.(results_df.pf_be_nl_no_dcr)/ input_data["branch"]["$(cable_id[3])"]["rate_a"]  # Convert to MWh
temp_profile_be_nl_no_dcr = compute_temperature_profile(abs_pf_be_nl_no_dcr)

# Calculate average temperatures
average_temperature_be_uk_no_dcr = sum(temp_profile_be_uk_no_dcr)/length(temp_profile_be_uk_no_dcr)
average_temperature_nl_uk_no_dcr = sum(temp_profile_nl_uk_no_dcr)/length(temp_profile_nl_uk_no_dcr)
average_temperature_be_nl_no_dcr = sum(temp_profile_be_nl_no_dcr)/length(temp_profile_be_nl_no_dcr)

# Calculate average temperatures with DCR
average_temperature_be_uk_dcr = sum(results_df.T_be_uk_dcr)/length(results_df.T_be_uk_dcr)
average_temperature_nl_uk_dcr = sum(results_df.T_nl_uk_dcr)/length(results_df.T_nl_uk_dcr)
average_temperature_be_nl_dcr = sum(results_df.T_be_nl_dcr)/length(results_df.T_be_nl_dcr)

# Print average temperatures
println("Average temperature of BE-UK cable without DCR: $average_temperature_be_uk_no_dcr °C")
println("Average temperature of BE-UK cable with DCR: $average_temperature_be_uk_dcr °C")
println("Average temperature of NL-UK cable without DCR: $average_temperature_nl_uk_no_dcr °C")
println("Average temperature of NL-UK cable with DCR: $average_temperature_nl_uk_dcr °C")
println("Average temperature of BE-NL cable without DCR: $average_temperature_be_nl_no_dcr °C")
println("Average temperature of BE-NL cable with DCR: $average_temperature_be_nl_dcr °C")

