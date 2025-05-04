# This function works with original model output. (EUGO, no DCR, without offshore grid) (full year simulation)
function determine_hours_of_ens!(result, input_data)
    gens_ens = []
    list_gens_ens_loc = []

    # Identify generators with ENS type.
    for (g, gen) in input_data["gen"]
        if gen["type"] == "ENS"
            push!(gens_ens, g)
            push!(list_gens_ens_loc, gen["node"])
        end
    end

    # Preallocate fixed-size arrays for each hour (assuming number_of_hours = 8760).
    num_of_gens_ens = zeros(Int, 8760)              # Count of ENS generators per hour.
    loc_gens_ens = [String[] for _ in 1:8760]         # List of locations per hour.
    ids_gens_ens = [String[] for _ in 1:8760]         # List of generator IDs per hour.
    load_shedded_hours = falses(8760)                 # Binary vector for load shedding.

    # Loop over each hour.
    for hour in 1:8760
        for g in gens_ens
            if result["$hour"]["solution"]["gen"][g]["pg"] > 0
                num_of_gens_ens[hour] += 1
                push!(loc_gens_ens[hour], input_data["gen"][g]["node"])
                push!(ids_gens_ens[hour], g)
            end
        end
        # Mark the hour as load shed if any ENS generator produced power.
        load_shedded_hours[hour] = num_of_gens_ens[hour] > 0   # Output: true or false
    end

    return num_of_gens_ens, loc_gens_ens, gens_ens, list_gens_ens_loc, ids_gens_ens, load_shedded_hours
end


# This function works with modified model output. (EUGO, no DCR, WITH offshore grid) (full year simulation)
function determine_hours_of_ens!(result, input_data, number_of_clusters, repetitions, prediction_horizon)

    gens_ens = []
    list_gens_ens_loc = []

    # Identify generators with ENS type.
    for (g, gen) in input_data["gen"]
        if gen["type"] == "ENS"
            push!(gens_ens, g)
            push!(list_gens_ens_loc, gen["node"])
        end
    end


    # Preallocate fixed-size arrays for each hour (assuming number_of_hours = 8760).
    num_of_gens_ens = zeros(Int, 8760)              # Count of ENS generators per hour.
    loc_gens_ens = [String[] for _ in 1:8760]         # List of locations per hour.
    ids_gens_ens = [String[] for _ in 1:8760]         # List of generator IDs per hour.
    load_shedded_hours = falses(8760)                 # Binary vector for load shedding.

    # Loop over all simulated hours
    reps_total = [0]
    reps = [0]
    hour = [0]

    for j in 1:number_of_clusters
        reps[1] = 0
        for i in repetitions[j]
            reps_total[1] += 1
            reps[1] += 1
            for network_hour in 1:prediction_horizon
                hour[1] = i + network_hour - 1
                for g in gens_ens
                    if result["$(reps_total[1])"]["solution"]["nw"]["$network_hour"]["gen"][g]["pg"] > 0
                        num_of_gens_ens[hour[1]] += 1
                        push!(loc_gens_ens[hour[1]], input_data["gen"][g]["node"])
                        push!(ids_gens_ens[hour[1]], g)
                    end
                end

                # Mark the hour as load shed if any ENS generator produced power.
                load_shedded_hours[hour[1]] = num_of_gens_ens[hour[1]] > 0      # Output: true or false
            end
        end
    end

    return num_of_gens_ens, loc_gens_ens, gens_ens, list_gens_ens_loc, ids_gens_ens, load_shedded_hours
end

### Get result ####
#num_of_gens_ens, loc_gens_ens, gens_ens, list_gens_ens_loc, ids_gens_ens, load_shedded_hours = determine_hours_of_ens!(result, input_data, number_of_clusters, repetitions, prediction_horizon)
num_of_gens_ens, loc_gens_ens, gens_ens, list_gens_ens_loc, ids_gens_ens, load_shedded_hours = determine_hours_of_ens!(result, input_data)
count(load_shedded_hours)
