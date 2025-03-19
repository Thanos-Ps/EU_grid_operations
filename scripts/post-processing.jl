using Plots

# Due to the temporal sampling, only 1 time slice (cluster) will be plotted (at least for now), to ensure continuity of time.
selected_cluster = 2
selected_cable = cable_id[1]
temperature_values = []
power_values = []
abs_power_values = []
diff_values = []
# Initialize counters
hour = [0]
reps_total = [0]
# Calibrate the reps_total counter to the beginning of the selected time slice.
reps_total[1] = length(repetitions[1])*(selected_cluster -1)

hours = 1:prediction_horizon*length(repetitions[selected_cluster])  # by doing that we are not plotting the last hour because the difference between pabs and p_to is large! (actual issue is not resloved)

for i in repetitions[selected_cluster]
    reps_total[1] += 1
    for network_hour in 1:prediction_horizon
        #hour[1] = i + network_hour - 1 
        T = result["$(reps_total[1])"]["solution"]["nw"]["$network_hour"]["branch"]["$selected_cable"]["Temperature"]
        p_to = 100*result["$(reps_total[1])"]["solution"]["nw"]["$network_hour"]["branch"]["$selected_cable"]["pt"]/input_data["branch"]["$selected_cable"]["rate_a"]
        p_abs = 100*result["$(reps_total[1])"]["solution"]["nw"]["$network_hour"]["branch"]["$selected_cable"]["p_abs"]/input_data["branch"]["$selected_cable"]["rate_a"]
        difference = p_abs - abs(p_to)
        push!(temperature_values, T)
        push!(power_values, p_to)
        #push!(abs_power_values, p_abs)
        push!(diff_values, difference)
    end

end

p1 = plot(hours, power_values, xlabel="Hour", ylabel="Rating [%]", title="Loading of Cable $selected_cable", legend = false)
#p1 = plot!(hours, abs_power_values, xlabel="Hour", ylabel="Rating [%]", title="Loading of Cable $selected_cable", legend = false)
p2 = plot(hours, abs_power_values, xlabel="Hour", ylabel="Rating [%]", title="Abs Power of Cable $selected_cable", legend = false)
p3 = plot(hours, temperature_values, xlabel="Hour", ylabel="[degC]", title="Temperature of Cable $selected_cable", legend = false)
p4 = plot(hours, diff_values, xlabel="Hour", title="P_abs - |P_to|", legend = false)
plot(p1,p4, p3, layout =(3,1))

###################################################################################################
# Relationship between hour and reps_total, nw for a given temporal sampling method and parameters.
# For a desired hour, get reps_total and nw to acces the data from the dictionary

selected_hour = 8093
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




