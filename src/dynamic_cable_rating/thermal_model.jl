# Functions to implement the thermal model of the offshore cables under dynamic rating.

# Question: Need to clarify whether output of admissible power refers to next hour or current hour.

function admissible_power!(power, temperature, time_constant = 100000, temp_to_pow_ratio = 0.9, admissible_power_per_degC = 1, temperature_reference = 12, time_step = 3600)
    #=

    This function applies a simple thermal model which calculates the admissible power and the new temperature of a cable 
    based on the injected power and its current temperature.

    The admissible power is calculated such that the thermal limits of the cable are respected.

    Several tuned parameters have been assigned such that the steady state behavior of the cable is normal.

    Input arguments:

    power : power transfer in [percentage of rated link power]

    temperature : cable temperature [degC], represents core temperature

    time_constant : RC time constant of power cable heating [sec]. Default is set to about 27-28 hours.  

    temp_to_pow_ratio : ratio of temperature to power, indicates how much one temperature increase is caused by one unit of power.

        Default is set to 0.8. This value has no physical meaning and the mere purpose is to make this simple model working.

        Set it higher to obtain higher temperature and lower admissible power.

    temperature_reference : temperature of the cable without power [degC]. Default cable environment temperature.

    time_step : time step between input values and returned values, default is set to 3600 seconds.
   
    Returns

    power_admissible : admissible power [% of rated power of link]

    temperature_new : updated cable temperature [degC]

    =#
    
    #TODO: how to include temperature_reference?
  
    temperature_new = temperature + (power*temp_to_pow_ratio - temperature)*(time_step/time_constant)
  
    temperature_delta = 90 - temperature_new
  
    power_admissible = 100 + temperature_delta*admissible_power_per_degC
  
    return power_admissible, temperature_new
  
end  

function store_adm_power_and_temperature!(cable_data, result, input_data_raw, iteration, hour, cable_id)
    #=

    This function determines the admissable power capacity and the temperature of the cables of the offshore meshed network (branches: 16, 92, 120, 121, 123)
    based on the scheduled power flow and the thermal model implemented by the function "admissible_power!".

    =#

    for cable in cable_id

        # Store the loading [%] of the offshore grid cables in the cable dictionary
        # Calculation: P_inj = P_scheduled/P_fixed * 100 [%]

        cable_data["$cable"]["$hour"]["P_inj"]["$iteration"] = 100 * abs(result["$hour"]["solution"]["branch"]["$cable"]["pt"])/input_data_raw["branch"]["$cable"]["rate_a"]
        # Store the active power flow of the offshore grid cables (to keep direction)
        cable_data["$cable"]["$hour"]["pt"]["$iteration"] = result["$hour"]["solution"]["branch"]["$cable"]["pt"]

        # Calculate the admissible power of the cables in percentage and update their temperature
        if hour < number_of_hours

            # If admissible power output refers to the next hour
            cable_data["$cable"]["$(hour+1)"]["P_adm"]["$iteration"], cable_data["$cable"]["$(hour+1)"]["temperature"]["$iteration"] = admissible_power!(cable_data["$cable"]["$hour"]["P_inj"]["$iteration"], cable_data["$cable"]["$hour"]["temperature"]["$iteration"])
            
            # If admissible power output refers to the current hour
            #cable_data["$cable"]["$iteration"]["$hour"]["P_adm"], cable_data["$cable"]["$iteration"]["$(hour+1)"]["temperature"]  = admissible_power!(cable_data["$cable"]["$iteration"]["$hour"]["P_inj"], cable_data["$cable"]["$iteration"]["$hour"]["temperature"])

        #else
            # over-write the new temperature on the current temperature (not useful info since simulation stops). But "else" is necessary since we need to store the admissible power of last hour
            #cable_data["$cable"]["$iteration"]["$hour"]["P_adm"], cable_data["$cable"]["$iteration"]["$hour"]["temperature"]  = admissible_power!(cable_data["$cable"]["$iteration"]["$hour"]["P_inj"], cable_data["$cable"]["$iteration"]["$hour"]["temperature"])
            # or just don't save this information, not necessary since we won't simulate after number_of_hours
        end
    end
   
end


