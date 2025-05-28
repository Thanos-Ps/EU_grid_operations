using Plots

function calculate_total_energy_exchanged(tyndp_version, number_of_clusters, repetitions, result)
    if tyndp_version == "2024"
        #ID of added branches:(converters)
        BE00_BEOS_id = 143
        NL00_NLOS_id = 144
        UK00_UKOS_id = 146
    elseif tyndp_version == "2020"
        #ID of added branches:(converters)
        BE00_BEOS_id = 120
        NL00_NLOS_id = 121
        UK00_UKOS_id = 127

    end 

    # Initialize results DataFrame
    results_df = _DF.DataFrame(
        pf_uk = Float64[],
        pf_be = Float64[],
        pf_nl = Float64[],
        total_power = Float64[],
    )

    # Initialize indexes
    reps = [0]
    reps_total = [0]
    hour = [0]

    for j in 1:number_of_clusters
        reps[1] = 0
        for i in repetitions[j]   
            reps[1] += 1        
            reps_total[1] += 1
            for network_hour in 1:prediction_horizon
                hour[1] = i + network_hour - 1 
                pf_uk = result["$(reps_total[1])"]["solution"]["nw"]["$network_hour"]["branch"]["$UK00_UKOS_id"]["pf"]
                pf_be = result["$(reps_total[1])"]["solution"]["nw"]["$network_hour"]["branch"]["$BE00_BEOS_id"]["pf"]
                pf_nl = result["$(reps_total[1])"]["solution"]["nw"]["$network_hour"]["branch"]["$NL00_NLOS_id"]["pf"]

                total_power = abs(pf_uk) + abs(pf_be) + abs(pf_nl)

                # Append the values to the DataFrame
                push!(results_df.pf_uk, pf_uk)
                push!(results_df.pf_be, pf_be)
                push!(results_df.pf_nl, pf_nl)
                push!(results_df.total_power, total_power)
            end
        end
    end

    # Calculate total energy exchanged through the meshed offshore grid
    tot_energy_exchanged = sum(results_df.total_power)


    return tot_energy_exchanged

end

#total_energy_exchanged = calculate_total_energy_exchanged(tyndp_version, number_of_clusters, repetitions, result)




selected_cable = 113
# Initiliaze results data frame
results_df = _DF.DataFrame(
    hour = Float64[],
    power_values = Float64[],
    temperature_values = Float64[],
)


# Initialize counters
hour = [0]
reps_total = [0]
# Calibrate the reps_total counter to the beginning of the selected time slice.
#reps_total[1] = length(repetitions[1])*(selected_cluster -1)

#hours = 1:prediction_horizon*length(repetitions[selected_cluster])  # by doing that we are not plotting the last hour because the difference between pabs and p_to is large! (actual issue is not resloved)
for j in 1:number_of_clusters
for i in repetitions[j]
    reps_total[1] += 1
    for network_hour in 1:prediction_horizon
        hour[1] = i + network_hour - 1 

        
        T = result["$(reps_total[1])"]["solution"]["nw"]["$network_hour"]["branch"]["$selected_cable"]["Temperature"]
        p_f = 100*result["$(reps_total[1])"]["solution"]["nw"]["$network_hour"]["branch"]["$selected_cable"]["pf"]/input_data["branch"]["$selected_cable"]["rate_a"]

       
        # Add the values to the results data frame
        push!(results_df, (hour = hour[1], power_values = p_f, 
        temperature_values = T
        ))

    end

end
end

# Save the results data frame to a CSV file
CSV.write("demo_cable_distributed.csv", results_df)


##########################################

power_values_hist = []

reps = [0]
reps_total = [0]
hour = [0]

# Extract the power values for the selected cable for all simulation time
for j in 1:number_of_clusters
    # reps counter is initialized to 0 before the sweeping of a new time slice starts.
    reps[1] = 0

    for i in repetitions[j]   

        reps[1] += 1        
        reps_total[1] += 1
        for network_hour in 1:prediction_horizon
            hour[1] = i + network_hour - 1 
            #T = result["$(reps_total[1])"]["solution"]["nw"]["$network_hour"]["branch"]["$selected_cable"]["Temperature"]
            p_f = 100*result["$(reps_total[1])"]["solution"]["nw"]["$network_hour"]["branch"]["$selected_cable"]["pf"]/input_data["branch"]["$selected_cable"]["rate_a"]

            #push!(temperature_values, T)
            push!(power_values_hist, p_f)

        end
    end
end

# Filter out power values that are not 0
power_values_no_zero = filter(x -> x != 0, power_values_hist)
# Convert power values to positive values
abs_power_values = abs.(power_values_no_zero)

# Filter out power values that are higher than 600
abs_power_values = filter(x -> x < 400, abs_power_values)
# Create histogram of power values
h1 = histogram(abs_power_values, bins=10, xlabel="Cable loading [%]", ylabel="Frequency", legend=false,
    linewidth = 1,
    color = :grey,
    framestyle=:box,
    #fontfamily = "Computer Modern",
    alpha = 1,
    tickfont=font(14, "Computer Modern"),
    guidefont=font(16, "Computer Modern"), 
    titlefont=font(14, "Computer Modern"),
    dpi=300, size=(800,600))
# Save the histogram
savefig(h1, "demo_cable_$selected_cable-histogram.png")






