#####################################
#  main.jl
# Author: Hakan Ergun 24.03.2022
# Script to solve the hourly ecomic dispatch problem for the TYNDP 
# reference grid based on NTC and provided genreation capacities
# RES and demand time series
#######################################


######### IMPORTANT: YOU WILL NEED TO DOWNLOAD THE FEATHER FILES AND ADD THEM TO YOUR data_sources FOLDER!!!!!!!
######### See data_sources/download_links.txt for the download links

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

tyndp_version = "2024"
fetch_data = true
number_of_hours = 8760

if tyndp_version == "2020"
  scenario = "DE"
  year = "2030"
  climate_year = "2007"

elseif tyndp_version == "2024"
  scenario = "DE"
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
T0 = 70                                                   # [degC], Initial temperature of the cables 
prediction_horizon = 24                                   # [hours], For the optimization problem 
time_elapsed = 3600                                       # [s], Time step of the simulation        
time_constant = 100000                                    # [s], Thermal time constant of the cables   
temp_to_pow_ratio = 0.9                                   # [degC/%], parameter of the thermal model
constraint_relax_factor = 10                              # [-], Factor to relax the constraints for the power limit of the dcr cables

# Create a dictionary that contains the DCR parameters
dcr_data = Dict{String, Any}(
  "Tmax" => Tmax,
  "T0" => T0,
  "prediction_horizon" => prediction_horizon, 
  "time_elapsed" => time_elapsed, 
  "time_constant" => time_constant, 
  "temp_to_pow_ratio" => temp_to_pow_ratio,
  "constraint_relax_factor" => constraint_relax_factor
  )

# Select the temporal sampling method and parameters
sampling_type_flag = "clusters"                           # Options: "clusters" or "rep_days"
number_of_clusters = 3
days_per_cluster = 1
rep_days = collect(1:10:365)

# Define capacities of branches in offshore grid in p.u. with base value 100 MVA
cable_capacity = 10
converter_capacity = 15      

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
  t, repetitions = temporal_sampling!(sampling_type_flag, rep_days, nothing)
elseif sampling_type_flag =="clusters"
  t, repetitions = temporal_sampling!(sampling_type_flag, number_of_clusters, days_per_cluster)
end


# Create dictionary for writing out results
# The result dictionary containts keys for each sweep of the whole simulation horizon from the prediction horizon, i.e. each repetition
# Basically the reps is a counter for the sweeps within each time slice. While the reps_total is a counter that summs all the sweeps of the time slices, to cover the whole simulation time.
# Warning: We assumed that each time slice has the same size. So it doesn't matter that we choose the size of the first vector of repetitions. Could be improved though...
result = Dict{String, Any}("$reps_total" => nothing for reps_total in 1:length(repetitions)*length(repetitions[1]))


# Initialize variables as arrays to avoid declaring global variables inside the loops
# Note: To access or update those variables inside the loop they should be called as reps[1] etc.
# reps is a counter that shows at which number of repetitions we are at (for the current time slice)
# As number of repetitions we refer to the loops carried out by the prediction horizon loop to sweep the time slice.
reps = [0]
reps_total = [0]
hour = [0]

# Replicate the input data for all the hours in the prediction horizon
mn_data = _PM.replicate(input_data,length(1:prediction_horizon))


for j in 1:number_of_clusters

  # reps counter is initialized to 0 before the sweeping of a new time slice starts.
  reps[1] = 0

  for i in repetitions[j]            # repeat the prediction horizon loops as many times needed to complete simulation time
    
    reps[1] += 1        
    reps_total[1] += 1

    # Update RES and demand data for the corresponding hours in the multi-network data
    # Each network represents an hour within the prediction horizon
    for network_hour in 1:prediction_horizon
      hour[1] = i + network_hour - 1
      _EUGO.prepare_hourly_data!(mn_data["nw"]["$network_hour"], nodal_data, hour[1])
    end
    # Solve the DCR-OPF problem for the given prediction horizon (simultaneously)
    result["$(reps_total[1])"] = DCROPF.solve_dcropf(mn_data, PowerModels.NFAPowerModel, solver, cable_id, dcr_data, result, reps[1], reps_total[1], prediction_horizon)
 
  end

end

"""
## Write out JSON files
# Result file, with hourly results
json_string = JSON.json(result)
result_file_name = joinpath(_EUGO.BASE_DIR, "results", "TYNDP"*tyndp_version, join(["result_zonal_tyndp_", scenario*year,"_", climate_year, ".json"]))
open(result_file_name,"w") do f
  JSON.print(f, json_string)
end

# Input data dictionary as .json file
input_file_name = joinpath(_EUGO.BASE_DIR, "results", "TYNDP"*tyndp_version,  join(["input_zonal_tyndp_", scenario*year,"_", climate_year, ".json"]))
json_string = JSON.json(input_data_raw)
open(input_file_name,"w") do f
  JSON.print(f, json_string)
end

# scenario file (e.g. zonal time series and installed capacities) as .json file
scenario_file_name = joinpath(_EUGO.BASE_DIR, "results", "TYNDP"*tyndp_version, join(["scenario_zonal_tyndp_", scenario*year,"_", climate_year, ".json"]))
json_string = JSON.json(nodal_data)
open(scenario_file_name,"w") do f
  JSON.print(f, json_string)
end

"""