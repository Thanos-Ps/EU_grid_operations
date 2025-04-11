function simulate_case!(input_data, nodal_data, solver, prediction_horizon, number_of_clusters, repetitions, cable_id, dcr_data)
    
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
            result["$(reps_total[1])"] = DCROPF.solve_dcropf(mn_data, PowerModels.NFAPowerModel, solver, cable_id, dcr_data, result, reps[1], reps_total[1], prediction_horizon, i)
        
        end

    end

    return result
end