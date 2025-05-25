function create_meshed_offshore_grid_owf!(input_data,cable_capacity, converter_capacity, owf_capacity, tyndp_version, climate_year, wind_offshore, nodal_data)
# Script to add new nodes and branches and create a zonal 5-node offshore meshed grid to examine dynaminc cable rating.

# Offshore grid: BE00, NL00, UK00 and Belgium offshore bus (BEOS), Netherlands offshore bus (NLOS), UK offshore bus (UKOS)
# Extra addition: OWF bus

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

# ID of the offshore windfarm bus
OWF_bus_id = 1000

# ID of the offshore windfarm branch (converter)
OWF_NLOS_id = 1001
OWF_UKOS_id = 1002

# ID of the offshore windfarm generator
OWF_gen_id = 10000

# Create a list that contains the IDs of the offshore cables to be used in the dynamic cable rating.
cable_id = [BE00_UK00_id, UK00_NL00_id, BEOS_NLOS_id]

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


# Adding offshore windfarm bus/zone/node  (OWF)
input_data["bus"]["$OWF_bus_id"] = Dict{String, Any}(
    # Modifiable values
    "lat" => 51.55,
    "lon" => 3.04,
    "string" => "OWF",
    "bus_i" => OWF_bus_id,
    "number" => OWF_bus_id,
    "source_id" => Any["bus",OWF_bus_id],
    "index" => OWF_bus_id,
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
    "rate_a" => converter_capacity,
    "rate_i" => converter_capacity,
    "rate_p" => converter_capacity,
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

# Branch: OWF - NLOS
input_data["branch"]["$OWF_NLOS_id"] = Dict{String, Any}(
    # Modifiable values
    "f_bus" => OWF_bus_id,
    "t_bus" => NLOS_id,
    "rate_a" => cable_capacity,
    "rate_i" => cable_capacity,
    "rate_p" => cable_capacity,
    "name" => "OWF-NLOS",
    "source_id" => Any["branch", OWF_NLOS_id],
    "number_id" => OWF_NLOS_id,
    "index" => OWF_NLOS_id,
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

# Branch: OWF - UKOS
input_data["branch"]["$OWF_UKOS_id"] = Dict{String, Any}(
    # Modifiable values
    "f_bus" => OWF_bus_id,
    "t_bus" => UKOS_id,
    "rate_a" => cable_capacity,
    "rate_i" => cable_capacity,
    "rate_p" => cable_capacity,
    "name" => "OWF-UKOS",
    "source_id" => Any["branch", OWF_UKOS_id],
    "number_id" => OWF_UKOS_id,
    "index" => OWF_UKOS_id,
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


# Adding the offshore windfarm generator
input_data["gen"]["$OWF_gen_id"] = Dict{String, Any}(
    "pg"                => 0.0,
    "model"             => 2,
    "shutdown"          => 0.0,
    "startup"           => 0.0,
    "qg"                => 0.0,
    "gen_bus"           => OWF_bus_id,
    "n_cost"            => 3,
    "pmax"              => owf_capacity,
    "vg"                => 1.0,
    "mbase"             => 100.0,
    "source_id"         => Any["gen", OWF_gen_id],
    "node"              => "OWF",
    "index"             => OWF_gen_id,
    "emissions"         => 0,
    "cost"              => [0.0, 6900.0, 0.0],
    "qmax"              => 0.0,
    "gen_status"        => 1,
    "qmin"              => 0.0,
    "inertia_constants" => 0,
    "type"              => "Offshore Wind",
    "pmin"              => 0.0
)

# Modify nodal data to add timeseries and capacity of OWF generator (assumption: same with BE offshore wind timeseries)

# Extract time series of BE offshore wind (in normalized values)
timeseries = convert(Vector{Float64}, wind_offshore[wind_offshore[!, "area"] .== "BE00", climate_year])
# Scale the time series to the capacity of the offshore wind farm
timeseries = timeseries .* (owf_capacity * 100)  # here it is MW so we multiply with base value

# Modify nodal data dictionary
nodal_data["OWF"] = Dict{String, Any}(
    "index" => OWF_bus_id,
    "demand" => [],
    "generation" => Dict{String, Any}(
        "Gas CCGT old 1"         => Dict{String, Any}("capacity"=>0.0),
        "Oil shale old"          => Dict{String, Any}("capacity"=>0.0),
        "Gas CCGT present 2"     => Dict{String, Any}("capacity"=>0.0),
        "Heavy oil old 2"        => Dict{String, Any}("capacity"=>0.0),
        "Gas CCGT present 1"     => Dict{String, Any}("capacity"=>0.0),
        "Gas OCGT old"           => Dict{String, Any}("capacity"=>0.0),
        "Hard coal old 1"        => Dict{String, Any}("capacity"=>0.0),
        "Gas OCGT new"           => Dict{String, Any}("capacity"=>0.0),
        "Light oil"              => Dict{String, Any}("capacity"=>0.0),
        "Heavy oil old 1"        => Dict{String, Any}("capacity"=>0.0),
        "Other non-RES"          => Dict{String, Any}("capacity"=>0.0),
        "Run-of-River"           => Dict{String, Any}("capacity"=>0.0),
        "Nuclear"                => Dict{String, Any}("capacity"=>0.0),
        "Lignite new"            => Dict{String, Any}("capacity"=>0.0),
        "Other RES"              => Dict{String, Any}("capacity"=>0.0),
        "Gas CCGT new"           => Dict{String, Any}("capacity"=>0.0),
        "Hard coal old 2"        => Dict{String, Any}("capacity"=>0.0),
        "Lignite old 1"          => Dict{String, Any}("capacity"=>0.0),
        "Gas Conventional old 2" => Dict{String, Any}("capacity"=>0.0),
        "Gas CCGT CCS"           => Dict{String, Any}("capacity"=>0.0),
        "Hard coal new"          => Dict{String, Any}("capacity"=>0.0),
        "Battery"                => Dict{String, Any}("capacity"=>0.0),
        "Reservoir"              => Dict{String, Any}("capacity"=>0.0),
        "Lignite CCS"            => Dict{String, Any}("capacity"=>0.0),
        "Hard coal CCS"          => Dict{String, Any}("capacity"=>0.0),
        "Gas CCGT old 2"         => Dict{String, Any}("capacity"=>0.0),
        "Gas Conventional old 1" => Dict{String, Any}("capacity"=>0.0),
        "Lignite old 2"          => Dict{String, Any}("capacity"=>0.0),
        "Oil shale new"          => Dict{String, Any}("capacity"=>0.0),
        "Onshore Wind"           => Dict{String, Any}(
            "timeseries"         => [],
            "capacity"           => 0.0
        ),
        "Solar PV"           => Dict{String, Any}(
            "timeseries"         => [],
            "capacity"           => 0.0
        ),
        "Offshore Wind"           => Dict{String, Any}(
            "timeseries"         => timeseries,
            "capacity"           => owf_capacity*100  # here it is MW so we multiply with base value
        )
    )
)

return cable_id

end

