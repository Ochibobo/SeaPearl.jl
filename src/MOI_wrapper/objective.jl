
"""
set and get function overloads
"""
#MOI.get(model::Optimizer, ::MOI.ObjectiveSense) = model.inner.sense

"""
function MOI.set(model::Optimizer, ::MOI.ObjectiveSense, sense::MOI.OptimizationSense)
    model.inner.sense = sense
    return
end
"""

"""
    MOI.set(model::Optimizer, MOI.ObjectiveFunction, func<:AbstractScalarFunction)

Set the objective function of your model. 
Support linear ones only at the moment put we will move to non-linear support soon. 
"""

# function MOI.set(model::Optimizer, ::MOI.ObjectiveFunction, svf::MOI.SingleVariable)
#     # get the VariableIndexs, convert them to strings and create 
#     id = string(svf.variable.value)

#     # tell the inner model that it is its objective !
#     model.cpmodel.objective = model.cpmodel.variables[id]
# end

function MOI.set(model::Optimizer, ::MOI.ObjectiveSense, sense::MOI.OptimizationSense)
    @assert sense == MOI.MIN_SENSE "CPRL does not support maximisation"
end

function MOI.set(model::Optimizer, ::MOI.ObjectiveFunction, saf::MOI.ScalarAffineFunction{T}) where {T<:Real}
    moiaff = MOIAffineFunction(nothing, saf)
    push!(model.moimodel.affines, moiaff)

    model.moimodel.objective_identifier = AffineIndex(length(model.moimodel.affines))
end
