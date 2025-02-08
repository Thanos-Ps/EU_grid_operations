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

# A sample set for TYNDP 2024
# tyndp_version = "2024"
# fetch_data = true
# number_of_hours = 8760
# scenario = "DE"
# year = "2050"
# climate_year = "2009"

# A sample set for TYNDP 2020
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


########################################################### MODIFICATIONS ############################################################################
prediction_horizon = 6                                           # Prediction horizon: Time horizon for the iterative solution that considers the admissible power
tolerance = 10^-1                                                # Acceptable tolerance of error for convergence
repetitions = collect(1:prediction_horizon:number_of_hours)      # find the "connecting points" of horizon loops (first hour of new loop)  
number_of_iterations = zeros(Int64, size(repetitions))           # Initialization of vector that stores the final number of iterations of each prediction horizon loop
starting_temperature = 75                                        # Cable temperature at the start of the simulation

# Insert id of cables with dynamic rating
cable_id = [16, 92, 123]


# Define capacities of branches in offshore grid in p.u. with base value 100 MVA
cable_capacity = 10
converter_capacity = 15      

# Include necessary scripts for functions, initializations and other operations
include("../src/dynamic_cable_rating/create_meshed_offshore_grid.jl")
create_meshed_offshore_grid!(input_data,cable_capacity,converter_capacity)
include("../src/dynamic_cable_rating/thermal_model.jl")
include("../src/dynamic_cable_rating/construct_cable_dict.jl")

# Initialize variables as arrays to avoid declaring global variables inside the loops
# Note: To access or update those variables inside the loop they should be called as reps[1], iteration[1],  max_error[1].
reps = [0]
iteration = [0]
max_error = [10.0]

######################################################

input_data_raw = deepcopy(input_data)


print("######################################", "\n")
print("### STARTING HOURLY OPTIMISATION ####", "\n")
print("######################################", "\n")


# Create dictionary for writing out results
result = Dict{String, Any}("$hour" => nothing for hour in 1:number_of_hours)

for i in repetitions            # repeat the horizon loops as many times needed to complete simulation time
  
  reps[1] += 1

  # Initialize error value and iteration number for the while loop to start -> so that new prediction horizon loop will start
  max_error[1] = 10.0
  iteration[1] = 0
  
  while max_error[1] > tolerance             # Iterate over the prediction horizon until convergence

    iteration[1] += 1
    println("Iteration ", iteration[1], "\n")

    for hour = i : 1 : i + prediction_horizon - 1     # Loop inside the prediction horizon (while book-keeping the "hour" counter)

      print("Hour ", hour, " of ", number_of_hours, "\n")
      # Write time series data into input data dictionary
      _EUGO.prepare_hourly_data!(input_data, nodal_data, hour, iteration[1], cable_data, cable_id, input_data_raw, i, number_of_iterations, reps[1], repetitions, starting_temperature)

      # Solve Network Flow OPF using PowerModels
      result["$hour"] = _PM.solve_opf(input_data, PowerModels.NFAPowerModel, solver) 

      store_adm_power_and_temperature!(cable_data, result, input_data_raw, iteration[1], hour, cable_id)

      # Store the error between the iterations for all the cables and all the hours within the prediction horizon
      if iteration[1] > 1
        for cable in cable_id
          error["$cable"]["$hour"] = abs(cable_data["$cable"]["$hour"]["temperature"]["$(iteration[1])"] - cable_data["$cable"]["$hour"]["temperature"]["$((iteration[1])-1)"])
        end
      end

    end

    if iteration[1] > 1  # Check for convergence starts after the first iteration

      # Set max_error to a very small value so that it's smaller during the first comparison with the elements of the error dictionary.
      max_error[1] = -Inf

      # Sweep all elements of the error dictionary to find the max_error.
      for cable in keys(error)
        for hour in keys(error[cable])
          max_error[1] = max(max_error[1], error[cable][hour])
        end
      end
      
    end

  end

  # Storing the number of iterations necessary for each prediction horizon loop to converge.
  number_of_iterations[reps[1]] = copy(iteration[1])
  
end


## Write out JSON files
# Result file, with hourly results
json_string = JSON.json(result)
result_file_name = join(["./results/result_zonal_tyndp_", scenario,"_", climate_year, ".json"])
open(result_file_name,"w") do f
  JSON.print(f, json_string)
end

# Input data dictionary as .json file
input_file_name = join(["./results/input_zonal_tyndp_", scenario,"_", climate_year, ".json"])
json_string = JSON.json(input_data_raw)
open(input_file_name,"w") do f
  JSON.print(f, json_string)
end

# scenario file (e.g. zonal time series and installed capacities) as .json file
scenario_file_name = join(["./results/scenario_zonal_tyndp_", scenario,"_", climate_year, ".json"])
json_string = JSON.json(nodal_data)
open(scenario_file_name,"w") do f
  JSON.print(f, json_string)
end
 

######################### MODIFICATIONS ############################
# Write out json file for cable_data dictionary
json_string = JSON.json(cable_data)
result_file_name = join(["./results/cable_data_zonal_tyndp_", scenario,"_", climate_year, ".json"])
open(result_file_name,"w") do f
  JSON.print(f, json_string)
end


# Check if the thermal limit of any cable was exceeded during simulation

# Create a dictionary that stores the hours where each cable exceeded its thermal limit (90 degC)
exceeded_hours = Dict{String, Dict{String, Any}}()
for cable in cable_id
  exceeded_hours["$cable"] = Dict{String, Any}()
  for hour in 1:number_of_hours
  exceeded_hours["$cable"]["$hour"] = false
  end
end

# Check the temperature of all cables during the simulation for violation of thermal limit and print warning.
# ATTENTION: repss is used here to avoid using the variable reps again which was used inside the main loop of the algorithm.
repss = [0]
for i in repetitions
  repss[1] += 1
  for hour = i : 1 : i + prediction_horizon - 1
    for cable in cable_id
      if cable_data["$cable"]["$hour"]["temperature"]["$(number_of_iterations[repss[1]])"]> 90
        exceeded_hours["$cable"]["$hour"] = true
        println("WARNING: Cable ", cable, " exceeded the thermal limit at Hour: ", hour, " (Temperature was: ", cable_data["$cable"]["$hour"]["temperature"]["$(number_of_iterations[repss[1]])"], " degC)")
      end
    end
  end
end




###################################################################



