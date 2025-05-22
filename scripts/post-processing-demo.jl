using Plots

# Due to the temporal sampling, only 1 time slice (cluster) will be plotted (at least for now), to ensure continuity of time.
selected_cluster = 2
selected_cable = cable_id[1]
temperature_values = []
power_values = []



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


        push!(temperature_values, T)
        push!(power_values, p_f)

    end

end


p1 = plot(hours, power_values,
        lw = 2, c =:black, xlabel="Time [Hour]", ylabel="Power Rating [%]",
        #title="Loading of Cable $selected_cable", 
        legend = false, 
        grid = false, framestyle=:box, 
        tickfont=font(14),
        guidefont=font(16), 
        titlefont=font(14),
        dpi=300, size=(800,600)
        )
        
p2 = plot(hours, temperature_values,
        lw = 2, c =:black, xlabel="Time [Hour]", ylabel="Temperature [°C]",
        #title="Loading of Cable $selected_cable", 
        legend = false, 
        grid = false, framestyle=:box, 
        tickfont=font(14),
        guidefont=font(16), 
        titlefont=font(14),
        dpi=300, size=(800,600)
        )

p3 = plot(p1, p2, layout =(2,1))

savefig(p3, "demo_cable_$selected_cable-month_$selected_cluster.png")

##################

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
"""
# Filter out power values that are not 0
power_values_no_zero = filter(x -> x != 0, power_values_hist)
# Convert power values to positive values
abs_power_values = abs.(power_values_hist)

# Filter out power values that are higher than 600
abs_power_values = filter(x -> x < 400, abs_power_values)
# Create histogram of power values
h1 = histogram(abs_power_values, bins=10, xlabel="Power Rating [%]", ylabel="Frequency", legend=false,
    linewidth = 1,
    color = :grey,
    framestyle=:box,
    alpha = 1,
    tickfont=font(14),
    guidefont=font(16), 
    titlefont=font(14),
    dpi=300, size=(800,600))
# Save the histogram
savefig(h1, "demo_cable_$selected_cable-histogram.png")

"""




