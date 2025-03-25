using Plots

# Due to the temporal sampling, only 1 time slice (cluster) will be plotted (at least for now), to ensure continuity of time.
selected_cluster = 20
selected_cable = cable_id[3]
temperature_values = []
power_values = []
diff_values = []
prob_hours = []


# Initialize counters
hour = [0]
reps_total = [0]
# Calibrate the reps_total counter to the beginning of the selected time slice.
reps_total[1] = length(repetitions[1])*(selected_cluster -1)

hours = 1:prediction_horizon*length(repetitions[selected_cluster])  # by doing that we are not plotting the last hour because the difference between pabs and p_to is large! (actual issue is not resloved)

for i in repetitions[selected_cluster]
    reps_total[1] += 1
    for network_hour in 1:prediction_horizon
        hour[1] = i + network_hour - 1 
        T = result["$(reps_total[1])"]["solution"]["nw"]["$network_hour"]["branch"]["$selected_cable"]["Temperature"]
        p_f = 100*result["$(reps_total[1])"]["solution"]["nw"]["$network_hour"]["branch"]["$selected_cable"]["pf"]/input_data["branch"]["$selected_cable"]["rate_a"]
        p_pos_f= 100*result["$(reps_total[1])"]["solution"]["nw"]["$network_hour"]["branch"]["$selected_cable"]["p_pos_f"]/input_data["branch"]["$selected_cable"]["rate_a"]
        p_neg_f = 100*result["$(reps_total[1])"]["solution"]["nw"]["$network_hour"]["branch"]["$selected_cable"]["p_neg_f"]/input_data["branch"]["$selected_cable"]["rate_a"]
        #difference = (p_f - (p_pos_f - p_neg_f))

        push!(temperature_values, T)
        push!(power_values, p_f)
        #push!(diff_values, difference)
    end

end

# Check if p_pos and p_neg are both not zero for any hour of the simulation
prob_hours = []
# Initialize counters
hour = [0]
reps_total = [0]
reps = [0]

for j in 1:number_of_clusters
    reps[1] = 0
    
    for i in repetitions[j]
        reps_total[1] += 1
        reps[1] += 1

        for network_hour in 1:prediction_horizon
            hour[1] = i + network_hour - 1 
            for cable in cable_id
                p_pos_f = 100*result["$(reps_total[1])"]["solution"]["nw"]["$network_hour"]["branch"]["$cable"]["p_pos_f"]/input_data["branch"]["$cable"]["rate_a"]
                p_neg_f = 100*result["$(reps_total[1])"]["solution"]["nw"]["$network_hour"]["branch"]["$cable"]["p_neg_f"]/input_data["branch"]["$cable"]["rate_a"]
            
                if p_pos_f*p_neg_f != 0 
                    if hour[1] != repetitions[j][reps[1]] + prediction_horizon - 1 # check if the hour is the last one from the prediction horizon and thus useless
                        push!(prob_hours, hour[1])
                    end
                end
            end
        end
    end
end

println("Problematic hours: ")
println("\n")
println(prob_hours)

p1 = plot(hours, power_values, xlabel="Hour", ylabel="Rating [%]", title="Loading of Cable $selected_cable", legend = false)
#p1 = plot!(hours, abs_power_values, xlabel="Hour", ylabel="Rating [%]", title="Loading of Cable $selected_cable", legend = false)
#p2 = plot(hours, abs_power_values, xlabel="Hour", ylabel="Rating [%]", title="Abs Power of Cable $selected_cable", legend = false)
p3 = plot(hours, temperature_values, xlabel="Hour", ylabel="[degC]", title="Temperature of Cable $selected_cable", legend = false)
#p4 = plot(hours, diff_values, xlabel="Hour", title="P_f - (P_f_pos - P_f_neg)", legend = false)
plot(p1, p3, layout =(2,1))

###################################################################################################
# Relationship between hour and reps_total, nw for a given temporal sampling method and parameters.
# For a desired hour, get reps_total and nw to acces the data from the dictionary

selected_hour = 1847
#selected_hour = repetitions[selected_cluster][1] + selected_hour - 1
# Initialize counters
reps_total = [0]
hour = [0]
nw = [0]

for j in 1:number_of_clusters                   # loop over the time slices/clusters
    for i in repetitions[j]                     # within each time slice, loop over the repetition anchors
        reps_total[1] += 1                      # keep track of which repetition we are at
        nw[1] = 0                               # initialize the network counter before entering the new prediction horizon loop
        for network in 1:prediction_horizon     # within each repetition, loop over the hours of the prediction horizon
            nw[1] += 1                          # keep track of which hour within the prediction hour we are at
            hour[1] = i + network - 1           # identify the actual hour we are at
            if hour[1]==selected_hour           # conditional
                return reps_total[1], nw[1]     # return the counters and break from all loops
            end
        end
    end
end

result["$(reps_total[1])"]["solution"]["nw"]["$(nw[1])"]["branch"]["$selected_cable"]


plot(p1, p3, layout =(2,1))