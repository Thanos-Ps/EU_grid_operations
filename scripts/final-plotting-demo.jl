# Import packages and create short names
import DataFrames; const _DF = DataFrames
import CSV
import JuMP
import Gurobi
import Feather
import PowerModels; const _PM = PowerModels
import JSON
using EU_grid_operations; const _EUGO = EU_grid_operations
using JSON
using Plots

selected_cable = 145

# Read CSV files for plotting
df_dcr = CSV.read("demo_cable_145_distributed_dcr.csv", _DF.DataFrame)
df_no_dcr = CSV.read("demo_cable_145_distributed-no-dcr.csv", _DF.DataFrame)

#power_flows = df_dcr.power_values

function admissible_power!(power, temperature, time_constant = 27*3600, temp_to_pow_ratio = 0.72, temperature_reference = 13, time_step = 3600)
  
    temperature_new = temperature + (abs(power)*temp_to_pow_ratio - (temperature - temperature_reference))*(time_step/time_constant)
  

    return temperature_new
  
end  

function compute_temperature_profile(power_vector;
    initial_temperature = 80.0,
    time_constant = 27*3600,
    temp_to_pow_ratio = 0.72,
    temperature_reference = 13,
    time_step = 3600)

    n = length(power_vector)
    temperature_vector = Vector{Float64}(undef, n)

    # Set the initial condition
    temperature_vector[1] = admissible_power!(
        power_vector[1],
        initial_temperature,
        time_constant,
        temp_to_pow_ratio,
        temperature_reference,
        time_step
    )

    # Iteratively compute the rest
    for t in 2:n
        temperature_vector[t] = admissible_power!(
            power_vector[t],
            temperature_vector[t-1],
            time_constant,
            temp_to_pow_ratio,
            temperature_reference,
            time_step
        )
    end

    return temperature_vector
end
temperature_profile_dcr = compute_temperature_profile(df_dcr.power_values);
temperature_profile_no_dcr = compute_temperature_profile(df_no_dcr.power_values);

absolute_power_dcr = abs.(df_dcr.power_values)
absolute_power_no_dcr = abs.(df_no_dcr.power_values)   

average_temperature_dcr = sum(temperature_profile_dcr)/length(temperature_profile_dcr)
average_temperature_no_dcr = sum(temperature_profile_no_dcr)/length(temperature_profile_no_dcr)

total_energy_dcr = sum((1/100)*(absolute_power_dcr)*input_data["branch"]["$selected_cable"]["rate_a"]*100) 
total_energy_no_dcr = sum((1/100)*(absolute_power_no_dcr)*input_data["branch"]["$selected_cable"]["rate_a"]*100)

# Print total energy exchanged
println("Total energy exchanged with DCR: $total_energy_dcr MWh")
println("Total energy exchanged without DCR: $total_energy_no_dcr MWh")


p1 = plot(df_dcr.hour, df_dcr.power_values,
        lw = 3, c =:black, xlabel="Time [h]", ylabel="Cable Loading [%]",
        grid = false, framestyle=:box, 
        label = "With DCR",
        #fontfamily = "Computer Modern",
        tickfont=font(14, "Computer Modern"),
        guidefont=font(16, "Computer Modern"), 
        titlefont=font(14, "Computer Modern"),
        dpi=300, size=(800,600)
        )
      
plot!(df_no_dcr.hour, df_no_dcr.power_values,
        lw = 3, c =:red, label = "Without DCR"
        #title="Loading of Cable $selected_cable", 
        )



p2 = plot(df_dcr.hour, df_dcr.temperature_values,
        lw = 3, c =:black, xlabel="Time [h]", ylabel="Cable Temperature [°C]",
        grid = false, framestyle=:box, 
        label = "With DCR",
        #fontfamily = "Computer Modern",
        tickfont=font(14, "Computer Modern"),
        guidefont=font(16, "Computer Modern"), 
        titlefont=font(14, "Computer Modern"),
        dpi=300, size=(800,600)
        )

plot!(df_no_dcr.hour, temperature_profile_no_dcr,
        lw = 3, c =:red, label = "Without DCR"
        )

p3 = plot(p1, p2, layout =(2,1), legend=:topright)
savefig(p3, "demo_cable_week.png")