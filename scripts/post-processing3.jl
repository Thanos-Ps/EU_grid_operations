
# Determine occurences of ENS in the simulation results

function determine_ens_times!(result, input_data, number_of_clusters, repetitions, prediction_horizon)
    # Initialize arrays
    gens_ens = []
    num_of_gens_ens = [0]


    # Identify generators with ENS type.
    for (g, gen) in input_data["gen"]
        if gen["type"] == "ENS"
            push!(gens_ens, g)
        end
    end

    # Loop over all simulated hours
    reps_total = [0]
    reps = [0]

    for j in 1:number_of_clusters
        reps[1] = 0
        for i in repetitions[j]
            reps_total[1] += 1
            reps[1] += 1
            for network_hour in 1:prediction_horizon
                # At each hour check if any ENS generator produced power
                for g in gens_ens
                    if result["$(reps_total[1])"]["solution"]["nw"]["$network_hour"]["gen"][g]["pg"] > 0
                        num_of_gens_ens[1] += 1
                    end
                end

            end

        end

    end

    return num_of_gens_ens

end


num_of_gens_ens = determine_ens_times!(result, input_data, number_of_clusters, repetitions, prediction_horizon)
num_of_gens_ens_ref = determine_ens_times!(result_ref, input_data, number_of_clusters, repetitions, prediction_horizon)
reduction = num_of_gens_ens_ref[1] - num_of_gens_ens[1]
println("Reduction in load shedding occurances: $(reduction)")
println("Load shedding occurances: $(num_of_gens_ens[1])")

