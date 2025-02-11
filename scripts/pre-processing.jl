# Script to perform a pre-processing analysis of the input data.
# The goal is to determine the hours where a selected cable is congested
# Also determine the hours of high renewable energy generation.
# Possibly, compare the two, to confirm that during High RE -> Examined cables are congested

# Attention: This file is based on the results located in the results folder.

using Plots

function determine_hours_of_congestion!(selected_cable, result, input_data_raw)
    # Discretize the range of cable loading in %
    y = LinRange(0, 100, 101)

    # Initialize array to store for how many hours the load is at least at a certain value
    hour_duration = zeros(length(y))

    # Initialize hour_id as a vector of empty integer vectors
    hour_id = [Int[] for _ in 1:length(y)-1]

    # Precompute current load for all hours
    number_of_hours = 8760  # Replace with actual number
    current_load = [100 * abs(result["$hour"]["solution"]["branch"]["$selected_cable"]["pt"]) / 
                    input_data_raw["branch"]["$selected_cable"]["rate_a"] for hour in 1:number_of_hours]

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


function determine_hours_of_high_re!(nodal_data, threshold)

    # Case Belgium
    # Wind onshore: timeseries, installed capacity
    wind_on_be = nodal_data["BE00"]["generation"]["Onshore Wind"]["timeseries"]
    wind_on_cap_be = nodal_data["BE00"]["generation"]["Onshore Wind"]["capacity"]
    # Wind offshore: timeseries, installed capacity, availability factor
    wind_off_be = nodal_data["BE00"]["generation"]["Offshore Wind"]["timeseries"]
    wind_off_cap_be = nodal_data["BE00"]["generation"]["Offshore Wind"]["capacity"]
    # PV: timeseries, installed capacity, availability factor
    pv_be = nodal_data["BE00"]["generation"]["Solar PV"]["timeseries"]
    pv_cap_be = nodal_data["BE00"]["generation"]["Solar PV"]["capacity"]

    # Calcualte sum of renewable generation at each hour
    re_sum_be = wind_on_be + wind_off_be + pv_be
    # Calculate sum of installed capacities of RE technologies
    re_sum_cap_be = wind_on_cap_be + wind_off_cap_be + pv_cap_be

    # Case Netherlands
    # Wind onshore: timeseries, installed capacity
    wind_on_nl = nodal_data["NL00"]["generation"]["Onshore Wind"]["timeseries"]
    wind_on_cap_nl = nodal_data["NL00"]["generation"]["Onshore Wind"]["capacity"]
    # Wind offshore: timeseries, installed capacity, availability factor
    wind_off_nl = nodal_data["NL00"]["generation"]["Offshore Wind"]["timeseries"]
    wind_off_cap_nl = nodal_data["NL00"]["generation"]["Offshore Wind"]["capacity"]
    # PV: timeseries, installed capacity, availability factor
    pv_nl = nodal_data["NL00"]["generation"]["Solar PV"]["timeseries"]
    pv_cap_nl = nodal_data["NL00"]["generation"]["Solar PV"]["capacity"]

    # Calcualte sum of renewable generation at each hour
    re_sum_nl = wind_on_nl + wind_off_nl + pv_nl
    # Calculate sum of installed capacities of RE technologies
    re_sum_cap_nl = wind_on_cap_nl + wind_off_cap_nl + pv_cap_nl

    # Case UK
    # Wind onshore: timeseries, installed capacity
    wind_on_uk = nodal_data["UK00"]["generation"]["Onshore Wind"]["timeseries"]
    wind_on_cap_uk = nodal_data["UK00"]["generation"]["Onshore Wind"]["capacity"]
    # Wind offshore: timeseries, installed capacity, availability factor
    wind_off_uk = nodal_data["UK00"]["generation"]["Offshore Wind"]["timeseries"]
    wind_off_cap_uk = nodal_data["UK00"]["generation"]["Offshore Wind"]["capacity"]
    # PV: timeseries, installed capacity, availability factor
    pv_uk = nodal_data["UK00"]["generation"]["Solar PV"]["timeseries"]
    pv_cap_uk = nodal_data["UK00"]["generation"]["Solar PV"]["capacity"]

    # Calcualte sum of renewable generation at each hour
    re_sum_uk = wind_on_uk + wind_off_uk + pv_uk
    # Calculate sum of installed capacities of RE technologies
    re_sum_cap_uk = wind_on_cap_uk + wind_off_cap_uk + pv_cap_uk

    # Sum all RE generations and installed capacities to get an average availability factor
    re_sum_tot = re_sum_be + re_sum_nl + re_sum_uk
    re_sum_cap_tot = re_sum_cap_be[1] + re_sum_cap_nl[1] + + re_sum_cap_uk[1] 

    af_aver = re_sum_tot ./ re_sum_cap_tot


    high_re_hours = af_aver .> threshold

    return high_re_hours

end


function determine_hours_of_re_level!(nodal_data, lower_level, upper_level)

    # Case Belgium
    # Wind onshore: timeseries, installed capacity
    wind_on_be = nodal_data["BE00"]["generation"]["Onshore Wind"]["timeseries"]
    wind_on_cap_be = nodal_data["BE00"]["generation"]["Onshore Wind"]["capacity"]
    # Wind offshore: timeseries, installed capacity, availability factor
    wind_off_be = nodal_data["BE00"]["generation"]["Offshore Wind"]["timeseries"]
    wind_off_cap_be = nodal_data["BE00"]["generation"]["Offshore Wind"]["capacity"]
    # PV: timeseries, installed capacity, availability factor
    pv_be = nodal_data["BE00"]["generation"]["Solar PV"]["timeseries"]
    pv_cap_be = nodal_data["BE00"]["generation"]["Solar PV"]["capacity"]

    # Calcualte sum of renewable generation at each hour
    re_sum_be = wind_on_be + wind_off_be + pv_be
    # Calculate sum of installed capacities of RE technologies
    re_sum_cap_be = wind_on_cap_be + wind_off_cap_be + pv_cap_be

    # Case Netherlands
    # Wind onshore: timeseries, installed capacity
    wind_on_nl = nodal_data["NL00"]["generation"]["Onshore Wind"]["timeseries"]
    wind_on_cap_nl = nodal_data["NL00"]["generation"]["Onshore Wind"]["capacity"]
    # Wind offshore: timeseries, installed capacity, availability factor
    wind_off_nl = nodal_data["NL00"]["generation"]["Offshore Wind"]["timeseries"]
    wind_off_cap_nl = nodal_data["NL00"]["generation"]["Offshore Wind"]["capacity"]
    # PV: timeseries, installed capacity, availability factor
    pv_nl = nodal_data["NL00"]["generation"]["Solar PV"]["timeseries"]
    pv_cap_nl = nodal_data["NL00"]["generation"]["Solar PV"]["capacity"]

    # Calcualte sum of renewable generation at each hour
    re_sum_nl = wind_on_nl + wind_off_nl + pv_nl
    # Calculate sum of installed capacities of RE technologies
    re_sum_cap_nl = wind_on_cap_nl + wind_off_cap_nl + pv_cap_nl

    # Case UK
    # Wind onshore: timeseries, installed capacity
    wind_on_uk = nodal_data["UK00"]["generation"]["Onshore Wind"]["timeseries"]
    wind_on_cap_uk = nodal_data["UK00"]["generation"]["Onshore Wind"]["capacity"]
    # Wind offshore: timeseries, installed capacity, availability factor
    wind_off_uk = nodal_data["UK00"]["generation"]["Offshore Wind"]["timeseries"]
    wind_off_cap_uk = nodal_data["UK00"]["generation"]["Offshore Wind"]["capacity"]
    # PV: timeseries, installed capacity, availability factor
    pv_uk = nodal_data["UK00"]["generation"]["Solar PV"]["timeseries"]
    pv_cap_uk = nodal_data["UK00"]["generation"]["Solar PV"]["capacity"]

    # Calcualte sum of renewable generation at each hour
    re_sum_uk = wind_on_uk + wind_off_uk + pv_uk
    # Calculate sum of installed capacities of RE technologies
    re_sum_cap_uk = wind_on_cap_uk + wind_off_cap_uk + pv_cap_uk

    # Sum all RE generations and installed capacities to get an average availability factor
    re_sum_tot = re_sum_be + re_sum_nl + re_sum_uk
    re_sum_cap_tot = re_sum_cap_be[1] + re_sum_cap_nl[1] + + re_sum_cap_uk[1] 

    af_aver = re_sum_tot ./ re_sum_cap_tot


    level_re_hours = (af_aver .> lower_level) .& (af_aver .< upper_level)

    return level_re_hours, af_aver

end


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


################### Load results from JSON files #######################

include("loading_results.jl")               # Attention: The selected scenario, climate year etc are located inside the loading_results.jl file!
result = result_json_dict
input_data_raw  = input_json_dict

########################################################################


# Determine congested hours as a 8760 element vector with boolean elements (True -> Congested)
congested_hours = determine_hours_of_congestion!(16,result,input_data_raw)
# Create a list that contains only the hours when congestion happens. It's length is useful for calcualtions.
congested_hours_list = findall(congested_hours)



function find_max_cost_generator(input_data, result, target_node, hour)
    # Access the generator list
    generators_all = input_data["gen"]  # Dictionary with all generators included in the input_data dictionary (larger)
    generators_zonal = result["$hour"]["solution"]["gen"] # Dictionary with all generators included in the results of the zonal model (smaller)
    dispatched = [] # Initialization of array that will store list of dispatched generators

    for (g,gen) in generators_zonal # Sweep through generators of zonal model 
        node = generators_all[g]["node"] # Extract the node name 
        if node == target_node && generators_zonal[g]["pg"] > 0 # check if they belong to target node (BE) and are dispatched
            push!(dispatched, g) # Store number of generator that satisfies conditional (type: String)
        end
    end

    # Among the dispatched, find the generator with the maximum cost (cost[2])
    max_cost = -Inf
    max_cost_gen = nothing

    for g in dispatched
        cost = generators_all[g]["cost"][2]  # Access the second element of the cost array
        if cost > max_cost
            max_cost = cost
            max_cost_gen = g
        end
    end

    
    return max_cost, max_cost_gen, dispatched
end


max_cost_UK = []
max_cost_BE = []
for hour in congested_hours_list
    max_cost_UK_now, max_cost_gen_UK_now, dispatched_UK_now  = find_max_cost_generator(input_data, result, "UK00", hour)
    append!(max_cost_UK, max_cost_UK_now)
    max_cost_BE_now, max_cost_gen_BE_now, dispatched_BE_now  = find_max_cost_generator(input_data, result, "BE00", hour)
    append!(max_cost_BE, max_cost_BE_now)
end
    
cost_diff = max_cost_UK .- max_cost_BE  # euro/pu * h
cost_diff_mwh = cost_diff/100


plot(cost_diff_mwh, xlabel = "Hours", ylabel = "Δprice [€/MWh]",title = "NL - UK interconnection", legend = false,
size=(800, 600), linewidth=2,xlabelfontsize=16,   # Bigger x-axis label font
     ylabelfontsize=16,   # Bigger y-axis label font
     titlefontsize=20,    # Bigger title font
     tickfontsize=14)


annual_savings = sum(abs.(cost_diff_mwh)*100)
aver_savings_per_hour = annual_savings/8760
aver_savings_per_day = aver_savings_per_hour*24

#=
max_cost_UK = []
max_cost_BE = []
cost_diff = zeros(8760,1)

for hour in 1:8760
    if congested_hours[hour] == true
    max_cost_UK_now, max_cost_gen_UK_now, dispatched_UK_now  = find_max_cost_generator(input_data, result, "UK00", hour)

    max_cost_BE_now, max_cost_gen_BE_now, dispatched_BE_now  = find_max_cost_generator(input_data, result, "BE00", hour)

    cost_diff_now = max_cost_UK_now - max_cost_BE_now
    cost_diff[hour] = cost_diff_now
    end
end
    

cost_diff_mwh = cost_diff/100


plot(cost_diff_mwh, xlabel = "Hours", ylabel = "Δprice [€/MWh]", title = "BE - UK interconnection", legend = false,
size=(800, 600), linewidth=2,xlabelfontsize=14,   # Bigger x-axis label font
     ylabelfontsize=14,   # Bigger y-axis label font
     titlefontsize=18,    # Bigger title font
     tickfontsize=12)
     #legendfontsize = 12)     # Bigger tick labels)

=#

#=

# Determine high RE hours as a 8760 element vector with boolean elements (True -> RE gen above threshold)
high_re_hours = determine_hours_of_high_re!(nodal_data,0.25)
# Create a list that contains only the hours when high RE occurs. It's length is useful for calcualtions.
high_re_hours_list = findall(high_re_hours)
# Compare the two hour vectors to find correlation
common_hours = congested_hours .& high_re_hours
# Create a list that contains the common hours.
common_hours_list = findall(common_hours)
# Show percentage of time that high re generation happens when line is congested
correlation_percentage = length(common_hours_list)/min(length(high_re_hours_list),length(congested_hours_list))

=#

#=
# Initialize a vector that will store the percentage of time periods that congestion and high renewable generation happen at the same time.
correlation_percentage = zeros(7,1)

# Loop over different RE generation values
for i in eachindex(correlation_percentage)
    #local threshold = i/10
    # Determine high RE hours as a 8760 element vector with boolean elements (True -> Congested)
    #local high_re_hours = determine_hours_of_high_re!(nodal_data,threshold)
    local level_re_hours, af_aver = determine_hours_of_re_level!(nodal_data, (i-1)/10,i/10)
    # Create a list that contains only the hours when high RE occurs. It's length is useful for calcualtions.
    #local high_re_hours_list = findall(high_re_hours)
    local level_re_hours_list = findall(level_re_hours)
    # Compare the two hour vectors to find correlation
    #local common_hours = congested_hours .& high_re_hours
    local common_hours = congested_hours .& level_re_hours
    # Create a list that contains the common hours.
    local common_hours_list = findall(common_hours)
    # Show percentage of time that high re generation happens when line is congested
    local correlation_percentage[i] = length(common_hours_list)/min(length(level_re_hours_list),length(congested_hours_list))

end

af_levels = collect(5:10:length(correlation_percentage)*10 -5)
correlation_percentage = 100*correlation_percentage
plot(af_levels, correlation_percentage, xlabel = "Average Availability factor of RE [%]", ylabel = "Matching occurance  [%]", legend = false )

=#








