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

# Define input parameters
tyndp_version = "2020"
fetch_data = true
number_of_hours = 24
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

# Make copy of input data dictionary as RES and demand data updated for each hour
input_data_raw = deepcopy(input_data)


# Select Dynamic cable rating parameters
Tmax = 90
T0 = 70

# Insert id of cables with dynamic rating
cable_id = [16, 92, 123]

# Define capacities of branches in offshore grid in p.u. with base value 100 MVA
cable_capacity = 10
converter_capacity = 15      

# Include necessary scripts for functions, initializations and other operations
include("../src/dynamic_cable_rating/create_meshed_offshore_grid.jl")
create_meshed_offshore_grid!(input_data,cable_capacity,converter_capacity)

# Create dictionary for writing out results
result = Dict{String, Any}("$hour" => nothing for hour in 1:number_of_hours)

starting_hour = 300
actual_hours = starting_hour:1:starting_hour + number_of_hours-1

mn_data = _PM.replicate(input_data,length(actual_hours))
#_IM.replicate(mp_data, length(t), Set{String}(["source_type", "name", "source_version", "per_unit"]))

for hour in hours
  _EUGO.prepare_hourly_data!(mn_data["nw"]["$hour"], nodal_data, hour)
end

result = DCROPF.solve_dcropf(mn_data, PowerModels.NFAPowerModel, solver, cable_id, Tmax, T0)

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