function create_meshed_offshore_grid!(input_data,cable_capacity, converter_capacity, tyndp_version)
# Script to add new nodes and branches and create a zonal 5-node offshore meshed grid to examine dynaminc cable rating.

# Offshore grid: BE00, NL00, UK00 and Belgium offshore bus (BEOS), Netherlands offshore bus (NLOS)

# Assumptions: Location of offshore nodes: Roughly the location of offshore windfarms of each country. 
# Capacity of new branches: 1 GW

# Possible improvements: Doing it in an automatic way (e.g. for loop) (check data.jl). Especially for larger grids!

# To be checked: zone types, bus types, default properties of branches

# Note: Location of nodes are not precise. It was a rough estimation. Should be looked further if necessary.

if tyndp_version == "2020"
    # Existing buses and branches with their indexes
    BE00_id = 4
    NL00_id = 42
    UK00_id = 63 
    BE00_UK00_id = 16
    UK00_NL00_id = 92

    # ID of added buses:
    BEOS_id = 65
    NLOS_id = 66    
    UKOS_id = 67

    #ID of added branches:
    BE00_BEOS_id = 120
    NL00_NLOS_id = 121
    BEOS_NLOS_id = 123
    UK00_UKOS_id = 127

elseif tyndp_version == "2024"
    # Existing buses and branches with their indexes
    BE00_id = 4
    NL00_id = 47
    UK00_id = 72 
    BE00_UK00_id = 20
    UK00_NL00_id = 113

    # ID of added buses:
    BEOS_id = 83
    NLOS_id = 84    
    UKOS_id = 85

    #ID of added branches:
    BE00_BEOS_id = 143
    NL00_NLOS_id = 144
    BEOS_NLOS_id = 145
    UK00_UKOS_id = 146

end


# Adding offshore Beglian bus/zone  (BEOS)
input_data["bus"]["$BEOS_id"] = Dict{String, Any}(
    # Modifiable values
    "lat" => 51.5,
    "lon" => 2.9,
    "string" => "BEOS",
    "bus_i" => BEOS_id,
    "number" => BEOS_id,
    "source_id" => Any["bus",BEOS_id],
    "index" => BEOS_id,
    # Default values
    "zone" => 1,
    "bus_type" => 2,
    "vmax" => 1.1,
    "area" => 1,
    "vmin" => 0.9,
    "va" => 0,
    "vm" => 1,
    "base_kv" => 400
)

# Adding offshore Netherlands bus/zone  (NLOS)
input_data["bus"]["$NLOS_id"] = Dict{String, Any}(
    # Modifiable values
    "lat" => 52.4,
    "lon" => 4.2,
    "string" => "NLOS",
    "bus_i" => NLOS_id,
    "number" => NLOS_id,
    "source_id" => Any["bus",NLOS_id],
    "index" => NLOS_id,
    # Default values
    "zone" => 1,
    "bus_type" => 2,
    "vmax" => 1.1,
    "area" => 1,
    "vmin" => 0.9,
    "va" => 0,
    "vm" => 1,
    "base_kv" => 400
)

# Adding offshore UK bus/zone  (UKOS)
input_data["bus"]["$UKOS_id"] = Dict{String, Any}(
    # Modifiable values
    "lat" => 51.3,
    "lon" => 1.44,
    "string" => "UKOS",
    "bus_i" => UKOS_id,
    "number" => UKOS_id,
    "source_id" => Any["bus",UKOS_id],
    "index" => UKOS_id,
    # Default values
    "zone" => 1,
    "bus_type" => 2,
    "vmax" => 1.1,
    "area" => 1,
    "vmin" => 0.9,
    "va" => 0,
    "vm" => 1,
    "base_kv" => 400
)


# Adding new branches to connect the three offshore nodes
# Branch: BE00 - BEOS
input_data["branch"]["$BE00_BEOS_id"] = Dict{String, Any}(
    # Modifiable values
    "f_bus" => BE00_id,
    "t_bus" => BEOS_id,
    "rate_a" => converter_capacity,
    "rate_i" => converter_capacity,
    "rate_p" => converter_capacity,
    "name" => "BE00-BEOS",
    "source_id" => Any["branch", BE00_BEOS_id],
    "number_id" => BE00_BEOS_id,
    "index" => BE00_BEOS_id,
    # Default values
    "br_r" => 0.0,
    "br_x" => 0.1,
    "g_to" => 0.0,
    "g_fr" => 0.0,
    "b_fr" => 0.0,
    "shift" => 0.0,
    "br_status" => 1,
    "b_to" => 0.0,
    "angmin" => -1.5707963267948966,
    "angmax" => -1.5707963267948966,
    "transformer" => false,
    "tap" => 1
)

# Branch: NL00 - NLOS 
input_data["branch"]["$NL00_NLOS_id"] = Dict{String, Any}(
    # Modifiable values
    "f_bus" => NL00_id,
    "t_bus" => NLOS_id,
    "rate_a" => converter_capacity,
    "rate_i" => converter_capacity,
    "rate_p" => converter_capacity,
    "name" => "NL00-NLOS",
    "source_id" => Any["branch", NL00_NLOS_id],
    "number_id" => NL00_NLOS_id,
    "index" => NL00_NLOS_id,
    # Default values
    "br_r" => 0.0,
    "br_x" => 0.1,
    "g_to" => 0.0,
    "g_fr" => 0.0,
    "b_fr" => 0.0,
    "shift" => 0.0,
    "br_status" => 1,
    "b_to" => 0.0,
    "angmin" => -1.5707963267948966,
    "angmax" => -1.5707963267948966,
    "transformer" => false,
    "tap" => 1
)

# Branch: BEOS - NLOS (Note: branch 122 was already existing in the TYNDP2020 version)
input_data["branch"]["$BEOS_NLOS_id"] = Dict{String, Any}(
    # Modifiable values
    "f_bus" => BEOS_id,
    "t_bus" => NLOS_id,
    "rate_a" => cable_capacity,
    "rate_i" => cable_capacity,
    "rate_p" => cable_capacity,
    "name" => "BEOS-NLOS",
    "source_id" => Any["branch", BEOS_NLOS_id],
    "number_id" => BEOS_NLOS_id,
    "index" => BEOS_NLOS_id,
    # Default values
    "br_r" => 0.0,
    "br_x" => 0.1,
    "g_to" => 0.0,
    "g_fr" => 0.0,
    "b_fr" => 0.0,
    "shift" => 0.0,
    "br_status" => 1,
    "b_to" => 0.0,
    "angmin" => -1.5707963267948966,
    "angmax" => -1.5707963267948966,
    "transformer" => false,
    "tap" => 1
)

# Branch: UK00 - UKOS
input_data["branch"]["$UK00_UKOS_id"] = Dict{String, Any}(
    # Modifiable values
    "f_bus" => UK00_id,
    "t_bus" => UKOS_id,
    "rate_a" => 2*converter_capacity,
    "rate_i" => 2*converter_capacity,
    "rate_p" => 2*converter_capacity,
    "name" => "UK00-UKOS",
    "source_id" => Any["branch", UK00_UKOS_id],
    "number_id" => UK00_UKOS_id,
    "index" => UK00_UKOS_id,
    # Default values
    "br_r" => 0.0,
    "br_x" => 0.1,
    "g_to" => 0.0,
    "g_fr" => 0.0,
    "b_fr" => 0.0,
    "shift" => 0.0,
    "br_status" => 1,
    "b_to" => 0.0,
    "angmin" => -1.5707963267948966,
    "angmax" => -1.5707963267948966,
    "transformer" => false,
    "tap" => 1
)

# Modifying existing lines (BE00-UK00 (NemoLink) and UK00-NL00) to connect with offshore nodes/buses instead of onshore nodes/buses.
# Branch: BE00-UK00 -> BEOS-UKOS 
input_data["branch"]["$BE00_UK00_id"]["f_bus"] = BEOS_id
input_data["branch"]["$BE00_UK00_id"]["t_bus"] = UKOS_id
input_data["branch"]["$BE00_UK00_id"]["name"] = "BEOS - UKOS"
input_data["branch"]["$BE00_UK00_id"]["rate_a"] = cable_capacity
input_data["branch"]["$BE00_UK00_id"]["rate_i"] = cable_capacity
input_data["branch"]["$BE00_UK00_id"]["rate_p"] = cable_capacity

# Branch: UK00-NL00 -> UKOS-NLOS
input_data["branch"]["$UK00_NL00_id"]["f_bus"] = UKOS_id
input_data["branch"]["$UK00_NL00_id"]["t_bus"] = NLOS_id
input_data["branch"]["$UK00_NL00_id"]["name"] = "UKOS - NLOS"
input_data["branch"]["$UK00_NL00_id"]["rate_a"] = cable_capacity
input_data["branch"]["$UK00_NL00_id"]["rate_i"] = cable_capacity
input_data["branch"]["$UK00_NL00_id"]["rate_p"] = cable_capacity

end

