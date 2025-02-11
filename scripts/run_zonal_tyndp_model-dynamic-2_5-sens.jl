# Script necessary for perfrorming the sensitivity analysis
# It simulates the system that implements dynamic cable rating


function simulate_dynamic_case!(input_data, nodal_data, cable_data, cable_id, t, number_of_clusters, number_of_iterations, prediction_horizon, starting_temperature, tolerance, error)


input_data_raw = deepcopy(input_data)


# Initialize variables as arrays to avoid declaring global variables inside the loops
# Note: To access or update those variables inside the loop they should be called as reps[1], iteration[1],  max_error[1].

# reps is a counter that shows at which number of repetitions we are at. 
# As number of repetitions we refer to the loops carried out by the prediction horizon loop to sweep the time slice.  (for the previous version it was the complete simulation time)
reps = [0]

iteration = [0]
max_error = [10.0]


print("######################################", "\n")
print("### STARTING HOURLY OPTIMISATION ####", "\n")
print("######################################", "\n")


# Create dictionary for writing out results
result = Dict{String, Any}()

for cluster_sample in t
  for hour in cluster_sample
    result["$hour"] = nothing
  end
end

# Start of simulation 

for j in 1:number_of_clusters

  # reps counter is initialized to 0 before the sweeping of a new time slice starts.
  reps[1] = 0

  for i in repetitions[j]            # repeat the horizon loops as many times needed to complete simulation time
    
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
        _EUGO.prepare_hourly_data!(input_data, nodal_data, hour, iteration[1], cable_data, cable_id, input_data_raw, i, number_of_iterations, reps[1], repetitions,j,starting_temperature)

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
    #number_of_iterations[reps[1]] = copy(iteration[1])
    number_of_iterations[j,reps[1]] = copy(iteration[1])
    
  end
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

for j in number_of_clusters
  repss[1] = 0
  for i in repetitions[j]
    repss[1] += 1
    for hour = i : 1 : i + prediction_horizon - 1
      for cable in cable_id
        if cable_data["$cable"]["$hour"]["temperature"]["$(number_of_iterations[j,repss[1]])"]> 90
          exceeded_hours["$cable"]["$hour"] = true
          println("WARNING: Cable ", cable, " exceeded the thermal limit at Hour: ", hour, " (Temperature was: ", cable_data["$cable"]["$hour"]["temperature"]["$(number_of_iterations[j,repss[1]])"], " degC)")
        end
      end
    end
  end
end

return result

end


