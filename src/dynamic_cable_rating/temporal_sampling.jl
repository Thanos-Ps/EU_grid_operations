# Temporal sampling

# Inputs for the function: 
# For "clusters" sampling: par1 = number_of_clusters, par2 = days_per_cluster
# For "rep_days" sampling: par1 = rep_days (array), par2 : not used

function temporal_sampling!(sampling_type_flag, prediction_horizon, par1, par2)

    if sampling_type_flag == "clusters"
        # Divide the year to N number of clusters.
        number_of_clusters = par1

        # Select number of days sampled for each cluster. The first N days of each cluster will be selected.
        days_per_cluster = par2

        # Identify the first hour of each cluster to form the time array t.
        first_hour_of_cluster = collect(Int64,1:number_of_hours/number_of_clusters:number_of_hours)

        # Create a time array t, that includes all the simulated hours. t has 2 dimensions. Each row represents a time cluster while each column represents an hour of the cluster.
        t = []
        for i in 1:number_of_clusters
        push!(t,collect(first_hour_of_cluster[i]:1:first_hour_of_cluster[i] + 24*days_per_cluster -1))
        end


        # The array repetitions will store the "connecting points" of horizon loops (first hour of new loop)  
        repetitions = []
        for i in 1:number_of_clusters
        push!(repetitions,collect(t[i][1]:prediction_horizon:t[i][end]))    # could use append! instead??
        end


    elseif sampling_type_flag == "rep_days"

        # Select the representative days for the simulation 
        rep_days = par1

        # Calculate number of representative days. Each day is considered a cluster by the main code.
        number_of_clusters = length(rep_days)

        # Create an array t, which includes the hours of the representative days. Every row corresponds to a day, while every column corresponds to an hour of the day.
        t = []
        for i in eachindex(rep_days)
        push!(t,collect((rep_days[i]-1)*24 + 1 : 1 : (rep_days[i]-1)*24 + 24))
        end

        # The array repetions will store the "connecting points" of horizon loops (first hour of new loop)  
        repetitions = []
        for i in eachindex(rep_days)
        push!(repetitions,collect(t[i][1]:prediction_horizon:t[i][end]))    # could use append! instead??
        end

    end

    return t, repetitions

end