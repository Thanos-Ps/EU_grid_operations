using Plots

cable_id = 16
temperature_values = []
power_values = []
abs_power_values = []
diff_values = []

hours = 1:number_of_hours-1

for hour in hours
          
    T = result["solution"]["nw"]["$hour"]["branch"]["$cable_id"]["Temperature"]
    p_to = 100*result["solution"]["nw"]["$hour"]["branch"]["$cable_id"]["pt"]/input_data["branch"]["$cable_id"]["rate_a"]
    p_abs = 100*result["solution"]["nw"]["$hour"]["branch"]["$cable_id"]["p_abs_t"]/input_data["branch"]["$cable_id"]["rate_a"]
    difference = p_abs - abs(p_to)
    push!(temperature_values, T)
    push!(power_values, p_to)
    #push!(abs_power_values, p_abs)
    push!(diff_values, difference)

end

p1 = plot(hours, power_values, xlabel="Hour", ylabel="Rating [%]", title="Loading of Cable $cable_id", legend = false)
#p1 = plot!(hours, abs_power_values, xlabel="Hour", ylabel="Rating [%]", title="Loading of Cable $cable_id", legend = false)
p2 = plot(hours, abs_power_values, xlabel="Hour", ylabel="Rating [%]", title="Abs Power of Cable $cable_id", legend = false)
p3 = plot(hours, temperature_values, xlabel="Hour", ylabel="[degC]", title="Temperature of Cable $cable_id", legend = false)
p4 = plot(hours, diff_values, xlabel="Hour", title="P_abs - |P_to|", legend = false)
plot(p1,p4, p3, layout =(3,1))


