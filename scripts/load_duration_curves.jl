# Script to create the load duration curves of the examined cables


# Attention: This file is based on the results located in the results folder.

using Plots

################### Load results from JSON files #######################

include("loading_results.jl")
result = result_json_dict
input_data_raw  = input_json_dict

########################################################################


# Select cable
selected_cable = 120

# Discretize the range of cable loading in %
y = LinRange(0, 100, 101)

# Initialize array to store for how many hours the load is at least at a certain value
hour_duration = zeros(length(y))

# Initialize hour_id as a vector of empty integer vectors
hour_id = [Int[] for _ in 1:length(y)-1]

# Precompute current load for all hours
number_of_hours = 8760  # Replace with actual number
current_load = [100 * abs(result["$hour"]["solution"]["branch"]["$selected_cable"]["pt"]) / 
                input_data_raw["branch"]["$selected_cable"]["rate_a"] for hour in 1:number_of_hours]

# Loop through thresholds and assign hours
for i in 1:length(y) -1
    for hour in 1:number_of_hours
        if current_load[hour] >= y[i]
            hour_duration[i] += 1
            push!(hour_id[i], hour)
        end
    end
end

# Normalize hour duration
hour_duration = 100 * hour_duration / maximum(hour_duration)

# Plot the load duration curve
plot(hour_duration, y, xlabel="Percentage in Time [%]", ylabel="Loading [%]",
#     title="Load duration Curves for NL-UK connection", label = "1 GW Converter",
     title="Load Duration Curve for Branch $selected_cable", legend = false,
     size=(800, 600), linewidth=2,xlabelfontsize=16,   # Bigger x-axis label font
     ylabelfontsize=16,   # Bigger y-axis label font
     titlefontsize=20,    # Bigger title font
     tickfontsize=14,
     legendfontsize = 12)     # Bigger tick labels


#=
     plot(hour_duration, y, xlabel="Percentage in Time [%]", ylabel="Loading [%]",
#     title="Load duration Curves for NL-UK connection", label = "1 GW Converter",
     title="Load Duration Curve for BE-NL connection", legend = false,
     size=(800, 600), linewidth=2,xlabelfontsize=16,   # Bigger x-axis label font
     ylabelfontsize=16,   # Bigger y-axis label font
     titlefontsize=20,    # Bigger title font
     tickfontsize=14,
     legendfontsize = 12)     # Bigger tick labels

=#
#=
# Select cable
selected_cable = 92

# Discretize the range of cable loading in %
y = LinRange(0, 100, 101)

# Initialize array to store for how many hours the load is at least at a certain value
hour_duration = zeros(length(y))

# Initialize hour_id as a vector of empty integer vectors
hour_id = [Int[] for _ in 1:length(y)-1]

# Precompute current load for all hours
number_of_hours = 8760  # Replace with actual number
current_load = [100 * abs(result["$hour"]["solution"]["branch"]["$selected_cable"]["pt"]) / 
                input_data_raw["branch"]["$selected_cable"]["rate_a"] for hour in 1:number_of_hours]

# Loop through thresholds and assign hours
for i in 1:length(y) - 1
    for hour in 1:number_of_hours
        if current_load[hour] >= y[i]
            hour_duration[i] += 1
            push!(hour_id[i], hour)
        end
    end
end

# Normalize hour duration
hour_duration = 100 * hour_duration / maximum(hour_duration)

# Plot the load duration curve
plot!(hour_duration, y, linewidth = 2, label = "1 GW Cable")


=#




























