# Post-processing of results


# Select type of results
results_flag = "obj_results"        # Options: "obj_results or "cable_results" or "injection_results" or "converter_results"

# Select cable (used in case of cable_results)
#selected_cable = 92                   # options: 16, 92, 123
#selected_converter = 121              # options: 120, 121, 127


if results_flag == "obj_results"

    global simulated_hours = length(t)*length(t[1])

    # Initialize variables to store sum, max, and min as local variables
    global objective_sum = 0.0
    global max_objective = -Inf
    global min_objective = Inf

    # Loop over all hours for the specified iteration

    for j in 1:number_of_clusters

        for hour in t[j]
            # Extract the objective value for each hour in the iteration
            objective_value = result["$hour"]["objective"]
            #objective_value = result_json_dict["$hour"]["objective"]            # if results are loaded use -> result_json_dict
            
            # Update the sum for calculating the mean later
            global objective_sum += objective_value
            
            # Update the maximum value
            if objective_value > max_objective
                global max_objective = objective_value
            end
            
            # Update the minimum value
            if objective_value < min_objective
                global min_objective = objective_value
            end
        end

    end

    # Calculate the mean by dividing the total sum by the number of hours
    global mean_objective = objective_sum / simulated_hours

    # Output the results
    println("Mean objective value : $mean_objective")
    println("Max objective value : $max_objective")
    println("Min objective value : $min_objective")

    println("\n")

end



# Commented section: If we ran the non-dynamic case for the whole year (version 2): run_zonal_tyndp_model_offshore-fixed

"""
if results_flag == "obj_results"
        
    # Initialize variables to store sum, max, and min as local variables
    global objective_sum = 0.0
    global max_objective = -Inf
    global min_objective = Inf

    # Loop over all hours for the specified iteration

    for hour in 1:number_of_hours
        # Extract the objective value for each hour in the iteration
        objective_value = result["$hour"]["objective"]
        #objective_value = result_json_dict["$hour"]["objective"]            # if results are loaded use -> result_json_dict
        
        # Update the sum for calculating the mean later
        global objective_sum += objective_value
        
        # Update the maximum value
        if objective_value > max_objective
            global max_objective = objective_value
        end
        
        # Update the minimum value
        if objective_value < min_objective
            global min_objective = objective_value
        end
    end
    

    # Calculate the mean by dividing the total sum by the number of hours
    global mean_objective = objective_sum / number_of_hours

    # Output the results
    println("Mean objective value : $mean_objective")
    println("Max objective value : $max_objective")
    println("Min objective value : $min_objective")

    println("\n")

end

"""