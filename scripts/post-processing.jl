# Post-processing of results


# Select type of results
results_flag = "obj_results"        # Options: "obj_results or "cable_results" or "injection_results" or "converter_results"

# Select cable (used in case of cable_results)
#selected_cable = 92                   # options: 16, 92, 123
#selected_converter = 121              # options: 120, 121, 127


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

    ################################################################################################

elseif results_flag == "cable_results"

    # Initialize counters for each case
    global count_above_100 = 0
    global count_equal_100 = 0
    global count_below_100 = 0

    # Initialize variables to sum P_inj and temperatures
    global P_inj_sum = 0.0
    global temperature_sum = 0.0
    global reps = 0

    # Loop over all hours
    for i in repetitions
        global reps += 1
        for hour = i : 1 : i + prediction_horizon - 1
        
            # Extract the P_inj value for the current hour
            P_inj = cable_data["$selected_cable"]["$hour"]["P_inj"]["$(number_of_iterations[reps])"]
            #P_inj = cable_data_json_dict["$selected_cable"]["$hour"]["P_inj"]["$(number_of_iterations_vector[reps])"]  # if results are loaded use-> cable_data_json_dict
            
            # Count based on the value of P_inj
            if P_inj > 100
                global count_above_100 += 1
            elseif P_inj == 100
                global count_equal_100 += 1
            else
                global count_below_100 += 1
            end

            # Sum P_inj and temperature values to calculate the means later
            global P_inj_sum += P_inj
            global temperature_sum += cable_data["$selected_cable"]["$hour"]["temperature"]["$(number_of_iterations[reps])"]
    
        end
    end

    # Calculate percentages
    percentage_above_100 = (count_above_100 / number_of_hours) * 100
    percentage_equal_100 = (count_equal_100 / number_of_hours) * 100
    percentage_below_100 = (count_below_100 / number_of_hours) * 100

    # Calculate the mean temperature
    global mean_temperature = temperature_sum / number_of_hours
    global mean_P_inj = P_inj_sum / number_of_hours

    # Output the results

    println("Results for cable $selected_cable:")
    println("Percentage of time P_inj > 100%: $percentage_above_100%")
    println("Percentage of time P_inj = 100%: $percentage_equal_100%")
    println("Percentage of time P_inj < 100%: $percentage_below_100%")
    println("Mean loading of cable $selected_cable: $mean_P_inj %")
    println("Mean temperature of cable $selected_cable: $mean_temperature °C")


elseif results_flag == "injection_results"
    global reps = 0

    println("Injection results for cable $selected_cable:")
    # Loop over all hours
    for i in repetitions
        global reps += 1
        for hour = i : 1 : i + prediction_horizon - 1
            println(cable_data["$selected_cable"]["$hour"]["pt"]["$(number_of_iterations[reps])"])
        end
    end

elseif results_flag == "converter_results"

    # Initialize counters for each case
    global count_equal_100 = 0
    global count_below_100 = 0

    # Initialize variables to sum P_inj and temperatures
    global P_inj_sum = 0.0
    global temperature_sum = 0.0


    # Loop over all hours that were simulated

    for hour in 1:number_of_hours
    
        # Extract the P_inj value for the current hour
        #P_inj = cable_data["$selected_cable"]["$hour"]["P_inj"]["$(number_of_iterations[j,reps])"]
        P_inj = 100*abs(result["$hour"]["solution"]["branch"]["$selected_converter"]["pt"])/input_data_raw["branch"]["$selected_converter"]["rate_a"]
        #P_inj = cable_data_json_dict["$selected_cable"]["$hour"]["P_inj"]["$(number_of_iterations_vector[reps])"]  # if results are loaded use-> cable_data_json_dict
        
        # Count based on the value of P_inj
        if P_inj == 100
            global count_equal_100 += 1
        else
            global count_below_100 += 1
        end

        # Sum P_inj and temperature values to calculate the means later
        global P_inj_sum += P_inj
        
    end
    
    # Calculate percentages
    percentage_equal_100 = (count_equal_100 / number_of_hours) * 100
    percentage_below_100 = (count_below_100 / number_of_hours) * 100

    # Calculate the mean temperature
    global mean_temperature = temperature_sum / number_of_hours
    global mean_P_inj = P_inj_sum / number_of_hours

    # Output the results

    println("Results for cable $selected_converter:")
    println("Percentage of time P_inj = 100%: $percentage_equal_100%")
    println("Percentage of time P_inj < 100%: $percentage_below_100%")
    println("Mean loading of cable $selected_converter: $mean_P_inj %")
    

end