
# Set the ids for the OWF generator and converter
selected_cable = 1001 # the converter connecting the windfarm 
selected_gen = 10000

# Initialize counters
reps = [0]
hour = [0]
reps_total = [0]

# Initialize arrays to store results
curtailment_hours = []

for j in 1:number_of_clusters
    reps[1] = 0
    for i in repetitions[j]            
        reps[1] += 1        
        reps_total[1] += 1
        for network_hour in 1:prediction_horizon
            hour[1] = i + network_hour - 1

            # either of two represent the actual power flowing from the OWF (results are in pu)
            #result["$(reps_total[1])"]["solution"]["nw"]["$network_hour"]["branch"]["$selected_cable"]["pf"]
            #result["$(reps_total[1])"]["solution"]["nw"]["$network_hour"]["gen"]["$selected_gen"]["pg"]

            # this represents the power available from the OWF (+ conversion to pu)
            #nodal_data["OWF"]["generation"]["Offshore Wind"]["timeseries"][hour[1]]/100
            
            # Extract them in MW
            owf_power_output = result["$(reps_total[1])"]["solution"]["nw"]["$network_hour"]["gen"]["$selected_gen"]["pg"]*100
            owf_power_available = nodal_data["OWF"]["generation"]["Offshore Wind"]["timeseries"][hour[1]]

            if owf_power_output < owf_power_available
                push!(curtailment_hours, hour[1])
            end
        end
    end
end 

# Find % of curtailment hours
tot_sim_hours = number_of_clusters*prediction_horizon*length(repetitions[1])
tot_sim_hours = number_of_clusters*length(t[1])
perc_of_curt = length(curtailment_hours)/tot_sim_hours *100
println("Percentage of curtailment: ", perc_of_curt, "%")

