function get_curtailment_hours(result, nodal_data, number_of_clusters, t, repetitions)
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

                if owf_power_output - owf_power_available < -1  #At least 1 MW of curtailment is required (to avoid numerical errors)
                    push!(curtailment_hours, hour[1])
                end
            end
        end
    end 

    # Find % of curtailment hours
    #tot_sim_hours = number_of_clusters*prediction_horizon*length(repetitions[1])
    tot_sim_hours = number_of_clusters*length(t[1])
    perc_of_curt = length(curtailment_hours)/tot_sim_hours *100

    return curtailment_hours, perc_of_curt

end

#curtailment_hours, perc_of_curt = get_curtailment_hours(result, nodal_data, number_of_clusters, t, repetitions)
#println("Percentage of curtailment: ", perc_of_curt, "%")


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


# Set scenario parameters
tyndp_version = "2024"

if tyndp_version == "2020"
  scenario = "NT"
  year = "2025"
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

# Define capacities of branches in offshore grid in p.u. with base value 100 MVA
examined_converters = [25]
examined_cable_deratings = [1.25]
examined_owf_capacity = [1, 3, 6, 10, 15, 20]


for owf_capacity in examined_owf_capacity
    for converter_capacity in examined_converters
        for ratio in examined_cable_deratings


            ################### DCR case ###################
            # Load the result JSON file as a string
            result_file_name = joinpath(
                _EUGO.BASE_DIR, 
                "results", 
                "TYNDP" * tyndp_version, 
                "result_zonal_tyndp_" * scenario * year * "_" * climate_year * "_" * converter_capacity * "_" * ratio * "_" * owf_capacity* ".json"
            )
            result_string = open(result_file_name) do f
                read(f, String)
            end

            # Now parse the string to get the dictionary
            result_json = JSON.parse(result_string)
            # It seems it needs parsing two times.
            result_json_dict = JSON.parse(result_json)


            # Save output dictionary temporarily (local variable)
            result = result_json_dict

            ####################### NO-DCR case #######################

            # Load the result_ref JSON file as a string
            result_file_name = joinpath(
                _EUGO.BASE_DIR, 
                "results", 
                "TYNDP" * tyndp_version, 
                "result_ref_zonal_tyndp_" * scenario * year * "_" * climate_year * "_" * converter_capacity * "_" * ratio * "_" * owf_capacity* ".json"
            )
            result_string = open(result_file_name) do f
                read(f, String)
            end

            # Now parse the string to get the dictionary
            result_json = JSON.parse(result_string)
            # It seems it needs parsing two times.
            result_json_dict = JSON.parse(result_json)

            # Save output dictionary temporarily (local variable)
            result_ref = result_json_dict

            #####################################

            # Determine curtailment hours
            curtailment_hours, perc_of_curt = get_curtailment_hours(result, nodal_data, number_of_clusters, t, repetitions)
            curtailment_hours_ref, perc_of_curt_ref = get_curtailment_hours(result_ref, nodal_data, number_of_clusters, t, repetitions)

        end

    end

end

        
    


"""
#### Post processing results_df #######
benefits = results_df[!, "economic_benefit_perc"]

plot(examined_owf_capacity, benefits,
        lw = 2, c =:black,
        xlabel="OWF capacity [GW]", ylabel="Economic benefits [%]",
        legend = false,
        grid = true, 
        framestyle=:box,
        marker = (:square, 4),
        tickfont = font(11, :bold), 
        guidefont = font(13, :bold),
        titlefont=font(14, "Times"),
        dpi=300, size=(600,400)
)

#######

"""