
function calculate_grid_usage(tyndp_version, number_of_clusters, repetitions, result)
    if tyndp_version == "2024"
        #ID of added branches:
        BE00_BEOS_id = 143
        NL00_NLOS_id = 144
        UK00_UKOS_id = 146
    elseif tyndp_version == "2020"
        #ID of added branches:
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
                #total_power = pf_uk + pf_be

                # Append the values to the DataFrame
                push!(results_df.pf_uk, pf_uk)
                push!(results_df.pf_be, pf_be)
                push!(results_df.pf_nl, pf_nl)
                push!(results_df.total_power, total_power)
            end
        end
    end

    # Calculate average power flowing through the meshed offshore grid
    average_power = sum(results_df.total_power)/length(results_df.total_power)


    return average_power

end

average_power = calculate_grid_usage(tyndp_version, number_of_clusters, repetitions, result)
println("Average power flowing through the meshed offshore grid: ", average_power/10, " GW/h")

