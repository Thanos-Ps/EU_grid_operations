# Pre-processing of curtailment level 
result = result_json_dict
#input_data = input_json_dict

function get_curtailment_hours_original(result, nodal_data, tyndp_version)

    # Set the id of offshore wind of belgium in the result dictionary
    if tyndp_version == "2024"
        selected_gen = 123 
    elseif tyndp_version == "2020"
        selected_gen = 165
    end

    # Initialize results DataFrame
    results_df = _DF.DataFrame(
        hour = Float64[],
        owf_power_available = Float64[],
        owf_power_output = Float64[],
        amount_of_curtailment = Float64[],
    )

    for hour in 1:8760
        # Extract the power output from the OWF generator [in MW]
        owf_power_output = result["$hour"]["solution"]["gen"]["$selected_gen"]["pg"] * 100

        # Extract the power available from the OWF [in MW]
        owf_power_available = nodal_data["BE00"]["generation"]["Offshore Wind"]["timeseries"][hour]

        # Check if there is curtailment
        if owf_power_output - owf_power_available < -1  #At least 1 MW of curtailment is required (to avoid numerical errors)
            amount_of_curtailment = owf_power_available - owf_power_output # in MW
        else
            amount_of_curtailment = 0
        end

        push!(results_df, (hour, owf_power_available, owf_power_output, amount_of_curtailment))

    end

    perc_of_curt = sum(results_df.amount_of_curtailment) / sum(results_df.owf_power_available) * 100
    
    return  perc_of_curt, results_df
end


perc_of_curt, results_df = get_curtailment_hours_original(result, nodal_data,tyndp_version)
println("Percentage of curtailment: ", perc_of_curt, "%")


