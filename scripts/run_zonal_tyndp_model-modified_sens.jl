# Script necessary for perfroming the sensitivity analysis
# It simulates the reference case of our system (without dynamic rating)

function simulate_reference_case!(input_data, nodal_data, cable_data, cable_id, t, number_of_clusters, number_of_iterations, prediction_horizon, starting_temperature)

input_data_raw = deepcopy(input_data)

iteration = nothing
reps = nothing

print("######################################", "\n")
print("### STARTING HOURLY OPTIMISATION ####", "\n")
print("######################################", "\n")

# Create dictionary for writing out results
#result = Dict{String, Any}("$hour" => nothing for hour in 1:number_of_hours)

result = Dict{String, Any}()

for cluster_sample in t
  for hour in cluster_sample
    result["$hour"] = nothing
  end
end


#for hour = 1:number_of_hours
for j in 1:number_of_clusters
  for i in repetitions[j]
    for hour = i : 1 : i + prediction_horizon - 1

      print("Hour ", hour, " of ", number_of_hours, "\n")
      # Write time series data into input data dictionary
      _EUGO.prepare_hourly_data!(input_data, nodal_data, hour, iteration, cable_data, cable_id, input_data_raw, i, number_of_iterations, reps, repetitions,j, starting_temperature)
      # Solve Network Flow OPF using PowerModels
      result["$hour"] = _PM.solve_opf(input_data, PowerModels.NFAPowerModel, solver) 
    
    end
  end
end


return result

end