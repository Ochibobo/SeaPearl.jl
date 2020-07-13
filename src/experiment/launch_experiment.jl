
"""
    launch_experiment!(;
        ValueSelectionArray::Array{ValueSelection, 1}, 
        problem_type::Symbol=:coloring,
        problem_params::Dict=coloring_params,
        nb_episodes::Int64=10,
        strategy::Type{DFSearch}=DFSearch,
        variableHeuristic=selectVariable
)

Same but with multiple ValueSelection instances (accepts BasicHeuristics)
We could rename it experiment and add a train::Bool argument.

Call it multitrain because I am having an overwritting error with the simple one 
and I would like to keep both atm.
"""
function launch_experiment!(
        valueSelectionArray::Array{T, 1}, 
        problem_type::Symbol,
        problem_params::Dict,
        nb_episodes::Int64,
        strategy::Type{DFSearch},
        variableHeuristic,
        metricsFun,
        verbose::Bool
    ) where T <: ValueSelection

    nb_heuristics = length(valueSelectionArray)

    fill_with_generator! = problem_generator[problem_type]

    bestsolutions = zeros(Int64, (nb_episodes, nb_heuristics))
    nodevisited = zeros(Int64, (nb_episodes, nb_heuristics))
    timeneeded = zeros(Float64, (nb_episodes, nb_heuristics))

    trailer = Trailer()
    model = CPModel(trailer)

    iter = ProgressBar(1:nb_episodes)
    for i in iter
    #for i in 1:nb_episodes
        verbose && print(" --- EPISODE: ", i)

        empty!(model)

        fill_with_generator!(model, problem_params)


        for j in 1:nb_heuristics
            reset_model!(model)
            
            dt = @elapsed search!(model, strategy, variableHeuristic, valueSelectionArray[j])

            if isa(valueSelectionArray[j], LearnedHeuristic)
                verbose && print(", Visited nodes: ", model.statistics.numberOfNodes)
            else
                verbose && print(" vs ", model.statistics.numberOfNodes)
            end

            bestsolutions[i, j] = model.objectiveBound + 1
            nodevisited[i, j] = model.statistics.numberOfNodes

            if j == 2
                set_postfix(iter, Delta=string(nodevisited[i, 1] - nodevisited[i, 2]))
            end

            timeneeded[i, j] = dt
            metricsFun(;episode=i, heuristic=valueSelectionArray[j], nodeVisited=model.statistics.numberOfNodes, bestSolution=(model.objectiveBound + 1))
        end
        verbose && println()

    end

    bestsolutions, nodevisited, timeneeded
end
