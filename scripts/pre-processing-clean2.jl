
# Import packages and create short names
import DataFrames; const _DF = DataFrames
import CSV
import JuMP
import Gurobi
import Feather
import PowerModels; const _PM = PowerModels
import JSON
using EU_grid_operations; const _EUGO = EU_grid_operations

function determine_hours_of_congestion!(selected_cable, result, input_data_raw, number_of_clusters, repetitions, prediction_horizon)
    # Discretize the range of cable loading in %
    y = LinRange(0, 100, 101)

    # Initialize array to store for how many hours the load is at least at a certain value
    hour_duration = zeros(length(y))

    # Initialize hour_id as a vector of empty integer vectors
    hour_id = [Int[] for _ in 1:length(y)-1]

    # Precompute current load for all hours
    number_of_hours = 8760  # Replace with actual number

    # Initilize current load array
    current_load = zeros(number_of_hours)

     # Loop over all simulated hours
    reps_total = [0]
    reps = [0]
    hour = [0]

    for j in 1:number_of_clusters
        reps[1] = 0
        for i in repetitions[j]
            reps_total[1] += 1
            reps[1] += 1
            for network_hour in 1:prediction_horizon
                hour[1] = i + network_hour - 1
                current_load[hour[1]] = 100* abs(result["$(reps_total[1])"]["solution"]["nw"]["$network_hour"]["branch"]["$selected_cable"]["pt"]) / 
                    input_data_raw["branch"]["$selected_cable"]["rate_a"]
            end
        end
    end

    # Loop through thresholds and assign hours
    for i in 1:length(y) - 1
        for hour in 1:number_of_hours
            if current_load[hour] >= y[i]
                hour_duration[i] += 1
                push!(hour_id[i], hour)
            end
        end
    end

    # Initialize a column vector with 8760 elements to store binary values
    congested_hours = falses(8760)
    congested_hours[hour_id[100]] .= true

    return congested_hours
end


tyndp_version = "2020"
fetch_data = true
number_of_hours = 8760

if tyndp_version == "2020"
  scenario = "NT"
  year = "2030"
  climate_year = "2007"

elseif tyndp_version == "2024"
  scenario = "NT"
  year = "2030"
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

# Select Dynamic Cable Rating parameters
Tmax = 90                                                 # [degC], Temperature limit of the cables 
T0 = 80                                                   # [degC], Initial temperature of the cables 
prediction_horizon = 1                                   # [hours], For the optimization problem 
time_elapsed = 3600                                       # [s], Time step of the simulation        
time_constant = 27*3600                                    # [s], Thermal time constant of the cables   
temp_to_pow_ratio = 0.72                                   # [degC/%], parameter of the thermal model
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
sampling_type_flag = "period"                           # Options: "clusters" or "rep_days" or "period"
number_of_clusters = 1
days_per_cluster = 7
rep_days = collect(1:10:365)
initial_day = 1
period_duration_days = 365


# Define capacities of branches in offshore grid in p.u. with base value 100 MVA
cable_capacity = 10
converter_capacity = 20   


# Include necessary scripts for functions, initializations and other operations
include("../src/dynamic_cable_rating/create_meshed_offshore_grid.jl")
include("../src/dynamic_cable_rating/temporal_sampling.jl")


# Modify the input_data dictionary to add the offshore grid and extract the cable_id vector
cable_id = create_meshed_offshore_grid!(input_data,cable_capacity,converter_capacity, tyndp_version)
# If you want to run the reference case (without DCR) -> set cable_id = []
cable_id = [] 

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


################### Load results from JSON files #######################

include("loading_results.jl")               # Attention: The selected scenario, climate year etc are located inside the loading_results.jl file!
result = result_json_dict
input_data_raw  = input_json_dict

########################################################################

# Determine congested hours as a 8760 element vector with boolean elements (True -> Congested)
congested_hours = determine_hours_of_congestion!(123,result,input_data_raw, number_of_clusters, repetitions, prediction_horizon)
# Create a list that contains only the hours when congestion happens. It's length is useful for calcualtions.
congested_hours_list = findall(congested_hours)

println("Congestion occurence: ", length(congested_hours_list)/8760*100, "%")



function find_max_cost_generator(input_data, result, target_node, hour)
    # Access the generator list
    generators_all = input_data["gen"]  # Dictionary with all generators included in the input_data dictionary (larger)
    generators_zonal = result["$hour"]["solution"]["nw"]["1"]["gen"] # Dictionary with all generators included in the results of the zonal model (smaller)
    dispatched_gens_id = [] # Initialization of array that will store list of dispatched generators
    dispatched_gens_type = []
    dispatched_gens_cost = []

    for (g,gen) in generators_zonal # Sweep through generators of zonal model 
        node = generators_all[g]["node"] # Extract the node name 
        if node == target_node && generators_zonal[g]["pg"] > 0 # check if they belong to target node (BE) and are dispatched
            push!(dispatched_gens_id, g) # Store number of generator that satisfies conditional (type: String)
            push!(dispatched_gens_type, generators_all[g]["type"]) # Store type of generator that satisfies conditional (type: String)
            push!(dispatched_gens_cost, generators_all[g]["cost"][2]) # Store cost of generator that satisfies conditional (type: Float)
        end
    end

    # Among the dispatched, find the generator with the maximum cost (cost[2])
    max_cost = -Inf
    max_cost_gen = nothing

    for g in dispatched_gens_id
        cost = generators_all[g]["cost"][2]  # Access the second element of the cost array
        if cost > max_cost
            max_cost = cost
            max_cost_gen = g
        end
    end

    
    return max_cost, max_cost_gen, dispatched_gens_id, dispatched_gens_type, dispatched_gens_cost
end



max_cost_UK = []
max_cost_BE = []
max_cost_NL = []

for hour in congested_hours_list
    max_cost_UK_now, max_cost_gen_UK_now, dispatched_UK_now  = find_max_cost_generator(input_data, result, "UK00", hour)
    append!(max_cost_UK, max_cost_UK_now)
    max_cost_BE_now, max_cost_gen_BE_now, dispatched_BE_now  = find_max_cost_generator(input_data, result, "BE00", hour)
    append!(max_cost_BE, max_cost_BE_now)
    max_cost_NL_now, max_cost_gen_NL_now, dispatched_BE_now  = find_max_cost_generator(input_data, result, "NL00", hour)
    append!(max_cost_NL, max_cost_NL_now)
end
    
cost_diff = max_cost_BE .- max_cost_UK  # euro/pu * h
cost_diff_mwh = cost_diff/100


num_of_pric_diff = count(x -> x != 0, cost_diff_mwh)
price_diff_mwh = filter(x -> x != 0, cost_diff_mwh)

println("Percentage of price differences during congestion: ", num_of_pric_diff/length(congested_hours_list)*100, "%")

# Create histogram of price differences
using Plots

histogram(price_diff_mwh,
    bins = 10,               # Number of bins (adjust as needed)
    xlabel = "Price Difference [€/MWh]",
    ylabel = "Frequency",
    legend = false,
    linewidth = 1,
    color = :grey,
    framestyle=:box,
    alpha = 1,
    tickfont=font(10),
    guidefont=font(12, "Times"), 
    titlefont=font(14, "Times"),
    dpi=300, size=(600,400))


#savefig("price_diff_histogram.png")

plot(cost_diff_mwh)