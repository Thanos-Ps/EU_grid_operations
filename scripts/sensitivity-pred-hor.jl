# Import packages and create short names
import DataFrames; const _DF = DataFrames
import CSV
import JuMP
import Gurobi
import Feather
import PowerModels; const _PM = PowerModels
import JSON
using EU_grid_operations; const _EUGO = EU_grid_operations
using DCROPF


function generate_temperature_array()
  # Total hours in a year
  total_hours = 8760
  # Days in a year (1 to 365)
  days = 1:365
  # Daily temperature values using a cosine function
  amplitude = 5.0
  vertical_shift = 13.0
  peak_day = 258  # Mid-September (day 258)
  T_day = amplitude .* cos.(2π/365 .* (days .- peak_day)) .+ vertical_shift
  # Expand daily values to hourly (repeat each value 24 times)
  T_hourly = repeat(T_day, inner=24)
  # Ensure the length matches 8760 hours
  @assert length(T_hourly) == total_hours
  return T_hourly
end

# Generate the temperature array
temperature_array = generate_temperature_array()

# Optional: Visualize the first week (24*7 = 168 hours)
#plot(temperature_array, xlabel="Hour", ylabel="Temperature (°C)", label="Hourly Temperature")


# Select your favorite solver
solver = JuMP.optimizer_with_attributes(Gurobi.Optimizer, "OutputFlag" => 0)


# Select the TYNDP version to be used:
tyndp_version = "2024"
fetch_data = true
number_of_hours = 8760

if tyndp_version == "2020"
  scenario = "DE"
  year = "2040"
  climate_year = "2007"

elseif tyndp_version == "2024"
  scenario = "GA"
  year = "2050"
  climate_year = "2009"
end

# Load grid and scenario data
if fetch_data == true
    pv, wind_onshore, wind_offshore = _EUGO.load_res_data()
    ntcs, nodes, arcs, capacity, demand, gen_types, gen_costs, emission_factor, inertia_constants, node_positions = _EUGO.get_grid_data(tyndp_version, scenario, year, climate_year)
end

# Construct input data dictionary in PowerModels style 
if tyndp_version == "2020"
  scenario_id = "$scenario$year"
elseif tyndp_version == "2024"
  scenario_id = "scenario"
end

input_data, nodal_data = _EUGO.construct_data_dictionary(tyndp_version, ntcs, arcs, capacity, nodes, demand, scenario_id, climate_year, gen_types, pv, wind_onshore, wind_offshore, gen_costs, emission_factor, inertia_constants, node_positions)


#Initialize lists to store results

results_df = _DF.DataFrame(
    prediction_horizon = Int[],
    cost_dcr = Float64[],
    cost_ref = Float64[],
    economic_benefit = Float64[],
    economic_benefit_in_perc = Float64[]
)

# Select examined horizons
examined_horizons = [24, 24*7, 24*30, 24*90]

for prediction_horizon in examined_horizons
    # Select Dynamic Cable Rating parameters
    Tmax = 90                                                 # [degC], Temperature limit of the cables 
    T0 = 80                                                   # [degC], Initial temperature of the cables 
    #prediction_horizon = 24                                   # [hours], For the optimization problem 
    time_elapsed = 3600                                       # [s], Time step of the simulation        
    time_constant = 27*3600                                    # [s], Thermal time constant of the cables   
    #temp_to_pow_ratio = 0.9                                   #[degC/%], parameter of the thermal model
    temp_to_pow_ratio = 0.72                                  # modified such that the steady state temperature is 90 degC, at T_amb = 18 degC. (Could be set for the worst case scenario of T_amb = 25 degC)
    constraint_relax_factor = 10                              # [-], Factor to relax the constraints for the power limit of the dcr cables
    #T_amb = 18                                                # [degC], Ambient temperature of the cables (the subsea temperature)

    # Create a dictionary that contains the DCR parameters
    dcr_data = Dict{String, Any}(
    "Tmax" => Tmax,
    "T0" => T0,
    "prediction_horizon" => prediction_horizon, 
    "time_elapsed" => time_elapsed, 
    "time_constant" => time_constant, 
    "temp_to_pow_ratio" => temp_to_pow_ratio,
    "constraint_relax_factor" => constraint_relax_factor,
    "temperature_array" => temperature_array
    )

    # Select the temporal sampling method and parameters
    sampling_type_flag = "period"                           # Options: "clusters" or "rep_days"  or "period"
    initial_day = 75
    period_duration_days = 90

    # Define capacities of branches in offshore grid in p.u. with base value 100 MVA
    cable_capacity = 10
    converter_capacity = 25     

    # Include necessary scripts for functions, initializations and other operations
    include("../src/dynamic_cable_rating/create_meshed_offshore_grid.jl")
    include("../src/dynamic_cable_rating/temporal_sampling.jl")

    # Modify the input_data dictionary to add the offshore grid and extract the cable_id vector
    cable_id = create_meshed_offshore_grid!(input_data,cable_capacity,converter_capacity, tyndp_version)

    # Make copy of input data dictionary as RES and demand data updated for each hour (and also include the created offhsore grid)
    input_data_raw = deepcopy(input_data)

    # Perform the temporal sampling based on the selected option
    number_of_clusters = 1
    t, repetitions = temporal_sampling!(sampling_type_flag, prediction_horizon, initial_day, period_duration_days)

    # Calculate the total number of repetitions to cover the whole simulation horizon 
    final_reps_total = number_of_clusters*length(repetitions[1])

    include("simulate_case.jl")

    # Run the dynamic case
    result = simulate_case!(input_data, nodal_data, solver, prediction_horizon, number_of_clusters, repetitions, cable_id, dcr_data)

    # Select no cables with DCR to simulate the reference case (DCR OFF)
    cable_id = []
        
    # Run the reference case
    result_ref = simulate_case!(input_data_raw, nodal_data, solver, prediction_horizon, number_of_clusters, repetitions, cable_id, dcr_data)

    # Calculate mean objective function per hour
    cost_ref = calculate_mean_obj(result_ref,final_reps_total, prediction_horizon)
    cost_dcr = calculate_mean_obj(result,final_reps_total, prediction_horizon)

    # Calculate economic benefits
    economic_benefit = cost_ref - cost_dcr
    economic_benefit_in_perc = (economic_benefit/cost_ref)*100

    # Store results
    push!(results_df, (prediction_horizon, cost_dcr, cost_ref, economic_benefit, economic_benefit_in_perc))


end

CSV.write("sensitivity_results_pred_horizon.csv", results_df)

p1 = plot(results_df.prediction_horizon, results_df.economic_benefit_in_perc,
    lw = 2, c =:black, xlabel="Optimization Horizon size [h]", ylabel="Economic Benefit [%]",
    marker = (:square, 6),
    legend = false, 
    grid = false, framestyle=:box, 
    #xticks = 1:13,
    tickfont=font(14),
    guidefont=font(16), 
    titlefont=font(14),
    dpi=300, size=(800,600)
    )


savefig(p1, "sensitivity-pred-hor.png")