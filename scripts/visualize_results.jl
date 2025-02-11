using Plots

# Select cable
cable_id = 123

# Select hour
hour = 6600

# Select type of plots
Flag1 = "over_hours"     #options: "over_hours" or "over_iterations"


# Initialize an array to store the power and the temperature values
power_values = []
temperature_values = []
global reps = 0


if Flag1 == "over_hours"

    # Create a time vector for the x-axis (optional)
    time_vals = 1:number_of_hours
    
    # Loop over all hours for the same iteration

    for i in repetitions
        global reps += 1
        for hour = i : 1 : i + prediction_horizon - 1
            power_transfer = 100 * result["$hour"]["solution"]["branch"]["$cable_id"]["pt"]/input_data_raw["branch"]["$cable_id"]["rate_a"]
            push!(power_values, power_transfer)

            temperature_evolution = cable_data["$cable_id"]["$hour"]["temperature"]["$(number_of_iterations[reps])"]
            push!(temperature_values, temperature_evolution)
        end
    end

    # Print results
    #=
    println("Loading of cable ", cable_id," over hours, at Iteration ", iteration)
    println(power_values)
    println("Temperature of cable ", cable_id," over hours, at Iteration ", iteration)
    println(temperature_values)
    =#

    # Plot the power and the temperature values over time
    p1 = plot(time_vals, power_values, xlabel="Hour", ylabel="Rating [%]", title="Loading of cable $cable_id over time", legend = false)
    p2 = plot(time_vals, temperature_values, xlabel="Hour", ylabel="Temperature [degC]", title="Temperature of Cable $cable_id over time", legend = false)
    plot(p1,p2, layout =(2,1))



elseif Flag1 == "over_iterations"

    # Identifying the index for reps (at which prediction horizon we are) based on input hour
    for j in 1:length(repetitions)
        if repetitions[j] > hour
            global reps = copy(j) - 1
            break

        else
            reps = length(repetitions)
        end
    end

    iteration_vector = 1:number_of_iterations[reps]
    
    # Loop over all iterations for the same hour

    for iteration in 1:number_of_iterations[reps]
        power_transfer = 100 * cable_data["$cable_id"]["$hour"]["pt"]["$iteration"]/input_data_raw["branch"]["$cable_id"]["rate_a"]
        push!(power_values, power_transfer)

        temperature_evolution = cable_data["$cable_id"]["$hour"]["temperature"]["$iteration"]
        push!(temperature_values, temperature_evolution)
    end

    # Print results
    #=
    println("Loading of cable ", cable_id," over iterations,  at Hour ", hour, )
    println(power_values)
    println("Temperature of cable ", cable_id," over iterations,  at Hour ", hour, )
    println(temperature_values)
    =#

    # Plot the power and the temperature values over iterations
    p1 = plot(iteration_vector, power_values, xlabel="Iteration", ylabel="Rating [%]", title="Loading of cable $cable_id at Hour $hour", legend = false)
    p2 = plot(iteration_vector, temperature_values, xlabel="Iteration", ylabel="Temperature [degC]", title="Temperature of Cable $cable_id at Hour $hour", legend = false)
    plot(p1,p2, layout =(2,1))
end
