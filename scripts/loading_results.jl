

# Import packages and create short names
import DataFrames; const _DF = DataFrames
import CSV
import JuMP
import Gurobi
import Feather
import PowerModels; const _PM = PowerModels
import JSON
using EU_grid_operations; const _EUGO = EU_grid_operations


using JSON
"""
scenario = "GA2030"
climate_year = "2007"
fetch_data = true
number_of_hours = 8760
"""


# Load the result JSON file as a string
result_file_name = joinpath(
    _EUGO.BASE_DIR, 
    "results", 
    "TYNDP" * tyndp_version, 
    "result_zonal_tyndp_" * scenario * year * "_" * climate_year * ".json"
)
result_string = open(result_file_name) do f
    read(f, String)
end

# Now parse the string to get the dictionary
result_json = JSON.parse(result_string)
# It seems it needs parsing two times.
result_json_dict = JSON.parse(result_json)


# Load the input data JSON file
input_file_name = joinpath(
    _EUGO.BASE_DIR, 
    "results", 
    "TYNDP" * tyndp_version, 
    "input_zonal_tyndp_" * scenario * year * "_" * climate_year * ".json"
)
input_string = open(input_file_name) do f
    read(f, String)
end
input_json = JSON.parse(input_string)
# It seems it needs parsing two times.
input_json_dict = JSON.parse(input_json)


# Load the scenario JSON file
scenario_file_name = joinpath(
    _EUGO.BASE_DIR, 
    "results", 
    "TYNDP" * tyndp_version, 
    "scenario_zonal_tyndp_" * scenario * year * "_" * climate_year * ".json"
)
scenario_string = open(scenario_file_name) do f
    read(f, String)
end
scenario_json = JSON.parse(scenario_string)
# It seems it needs parsing two times.
scenario_json_dict = JSON.parse(scenario_json)


# Load the parameters JSON file as a string
parameters_file_name = joinpath(
    _EUGO.BASE_DIR, 
    "results", 
    "TYNDP" * tyndp_version, 
    "parameters_zonal_tyndp_" * scenario * year * "_" * climate_year * ".json"
)
parameters_string = open(parameters_file_name) do f
    read(f, String)
end

# Now parse the string to get the dictionary
parameters_json = JSON.parse(parameters_string)
# It seems it needs parsing two times.
parameters_json_dict = JSON.parse(parameters_json)
