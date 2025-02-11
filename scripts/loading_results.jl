using JSON

scenario = "GA2030"
climate_year = "2007"
fetch_data = true
number_of_hours = 8760

# Load the result JSON file as a string
result_file_name = join(["./results/result_zonal_tyndp_", scenario, "_", climate_year, ".json"])
result_string = open(result_file_name) do f
    read(f, String)
end

# Now parse the string to get the dictionary
result_json = JSON.parse(result_string)
# It seems it needs parsing two times.
result_json_dict = JSON.parse(result_json)


# Load the input data JSON file
input_file_name = join(["./results/input_zonal_tyndp_", scenario, "_", climate_year, ".json"])
input_string = open(input_file_name) do f
    read(f, String)
end
input_json = JSON.parse(input_string)
# It seems it needs parsing two times.
input_json_dict = JSON.parse(input_json)


# Load the scenario JSON file
scenario_file_name = join(["./results/scenario_zonal_tyndp_", scenario, "_", climate_year, ".json"])
scenario_string = open(scenario_file_name) do f
    read(f, String)
end
scenario_json = JSON.parse(scenario_string)
# It seems it needs parsing two times.
scenario_json_dict = JSON.parse(scenario_json)


# Load the cable_data JSON file as a string
cable_data_file_name = join(["./results/cable_data_zonal_tyndp_", scenario, "_", climate_year, ".json"])
cable_data_string = open(cable_data_file_name) do f
    read(f, String)
end

# Now parse the string to get the dictionary
cable_data_json = JSON.parse(cable_data_string)
# It seems it needs parsing two times.
cable_data_json_dict = JSON.parse(cable_data_json)

