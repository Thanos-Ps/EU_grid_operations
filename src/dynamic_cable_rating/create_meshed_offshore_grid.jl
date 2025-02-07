function create_meshed_offshore_grid!(input_data,cable_capacity, converter_capacity)
# Script to add new nodes and branches and create a zonal 5-node offshore meshed grid to examine dynaminc cable rating.

# Offshore grid: BE00, NL00, UK00 and Belgium offshore bus (BEOS), Netherlands offshore bus (NEOS)

# Assumptions: Location of offshore nodes: Roughly the location of offshore windfarms of each country. 
# Capacity of new branches: 1 GW

# Possible improvements: Using functions instead of doing it manually. (check data.jl). Especially for larger grids!

# To be checked: zone types, bus types, default properties of branches

# Note: Location of nodes are not precise. It was a rough estimation. Should be looked further if necessary.


# BUS BE00 : 4
# BUS NL00 : 42
# BUS UK00 : 63 

# Adding offshore Beglian bus/zone  (BEOS)
input_data["bus"]["65"] = Dict{String, Any}(
    # Modifiable values
    "lat" => 51.5,
    "lon" => 2.9,
    "string" => "BEOS",
    "bus_i" => 65,
    "number" => 65,
    "source_id" => Any["bus",65],
    "index" => 65,
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

# Adding offshore Netherlands bus/zone  (NEOS)
input_data["bus"]["66"] = Dict{String, Any}(
    # Modifiable values
    "lat" => 52.4,
    "lon" => 4.2,
    "string" => "NEOS",
    "bus_i" => 66,
    "number" => 66,
    "source_id" => Any["bus",66],
    "index" => 66,
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
input_data["bus"]["67"] = Dict{String, Any}(
    # Modifiable values
    "lat" => 51.3,
    "lon" => 1.44,
    "string" => "UKOS",
    "bus_i" => 67,
    "number" => 67,
    "source_id" => Any["bus",67],
    "index" => 67,
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


# Adding new branches to connect the two offshore nodes
# Branch 120: BE00 (bus 4) - BEOS (bus 65)
input_data["branch"]["120"] = Dict{String, Any}(
    # Modifiable values
    "f_bus" => 4,
    "t_bus" => 65,
    "rate_a" => converter_capacity,
    "rate_i" => converter_capacity,
    "rate_p" => converter_capacity,
    "name" => "BE00-BEOS",
    "source_id" => Any["branch", 120],
    "number_id" => 120,
    "index" => 120,
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

# Branch 121: NL00 (bus 42) - NLOS (bus 66)
input_data["branch"]["121"] = Dict{String, Any}(
    # Modifiable values
    "f_bus" => 42,
    "t_bus" => 66,
    "rate_a" => converter_capacity,
    "rate_i" => converter_capacity,
    "rate_p" => converter_capacity,
    "name" => "NL00-NLOS",
    "source_id" => Any["branch", 121],
    "number_id" => 121,
    "index" => 121,
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


# Branch 123: BEOS (bus 65) - NLOS (bus 66) (Note: branch 122 was already existing)
input_data["branch"]["123"] = Dict{String, Any}(
    # Modifiable values
    "f_bus" => 65,
    "t_bus" => 66,
    "rate_a" => cable_capacity,
    "rate_i" => cable_capacity,
    "rate_p" => cable_capacity,
    "name" => "BEOS-NLOS",
    "source_id" => Any["branch", 123],
    "number_id" => 123,
    "index" => 123,
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

# Branch 127: UK00 (bus 63) - UKOS (bus 67)
input_data["branch"]["127"] = Dict{String, Any}(
    # Modifiable values
    "f_bus" => 63,
    "t_bus" => 67,
    "rate_a" => 2*converter_capacity,
    "rate_i" => 2*converter_capacity,
    "rate_p" => 2*converter_capacity,
    "name" => "UK00-UKOS",
    "source_id" => Any["branch", 127],
    "number_id" => 127,
    "index" => 127,
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

# Modifying existing lines (BE00-UK00 (NemoLink) and UK00-NL00 (LionLink?)) to connect with offshore nodes/buses instead of onshore nodes/buses.
# Branch 16 : BE00-UK00 -> BEOS-UKOS 
input_data["branch"]["16"]["f_bus"] = 65
input_data["branch"]["16"]["t_bus"] = 67
input_data["branch"]["16"]["name"] = "BEOS - UKOS"
input_data["branch"]["16"]["rate_a"] = cable_capacity
input_data["branch"]["16"]["rate_i"] = cable_capacity
input_data["branch"]["16"]["rate_p"] = cable_capacity

# Branch 92: UK00-NL00 -> UKOS-NLOS
input_data["branch"]["92"]["f_bus"] = 67
input_data["branch"]["92"]["t_bus"] = 66
input_data["branch"]["92"]["name"] = "UK00 - NLOS"
input_data["branch"]["92"]["rate_a"] = cable_capacity
input_data["branch"]["92"]["rate_i"] = cable_capacity
input_data["branch"]["92"]["rate_p"] = cable_capacity

########################################


end

