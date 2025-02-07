# Script to construct data dictionary for the dynamic cable rating calculations.

# Assumptions: 
# Temperature of cables at the start of the simulation: 75 degC
# Fixed capacity of cables: 1 GW

cable_data = Dict{String, Dict{String, Dict{String, Dict{String,Any}}}}()


for cable in cable_id
    cable_data["$cable"] = Dict{String, Dict{String, Dict{String,Any}}}()

    for hour in 1:number_of_hours
        cable_data["$cable"]["$hour"] = Dict{String, Dict{String,Any}}()

        cable_data["$cable"]["$hour"]["P_adm"] = Dict{String, Any}()
        cable_data["$cable"]["$hour"]["P_inj"] = Dict{String, Any}()
        cable_data["$cable"]["$hour"]["temperature"] = Dict{String, Any}()
        cable_data["$cable"]["$hour"]["pt"] = Dict{String, Any}()
    end

end


error = Dict{String, Dict{String, Any}}()

for cable in cable_id
    error["$cable"] = Dict{String, Any}()

    for hour in  1:number_of_hours
        error["$cable"]["$hour"] = 0
    end

end

# Create a dictionary where the maximum error of each cable among the iterations is stored
#=
max_cable_error = Dict{String, Any}()

for cable in cable_id
    max_cable_error["$cable"] = nothing
end
=#

# Need to initialize temperature. (at least for first hour of simulation)

# If thermal model output refers to the next hour, it's necessary to set admissible power of the first hour of simulation equal to fixed capacity:

#= could be put in the data.jl for constant updating in every first iteration (due to new form)
for cable in cable_id
    for iteration in 1:number_of_iterations
        cable_data["$cable"]["$iteration"]["1"]["P_adm"] = 100
    end
end
=#

# Initialize admissible power and temperature for 1st hour of simulation
# Maybe not necessary since it's updated in the data.jl?
#=  not necessary since it's updated every time (even at the start) by prepare_hourly_data!
for cable in cable_id
    cable_data["$cable"]["1"]["P_adm"]["1"] = 100
    cable_data["$cable"]["1"]["temperature"]["1"] = 75
end
=#

