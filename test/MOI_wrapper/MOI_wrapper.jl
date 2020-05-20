using MathOptInterface

const MOI = MathOptInterface
const MOIU = MathOptInterface.Utilities

using JuMP

@testset "MOI_wrapper.jl" begin

    @testset "Creating an optimizer" begin
        model = CPRL.Optimizer()
        @test MOI.get(model, MOI.SolverName()) == "CPRL Solver"
    end

    @testset "Giving parameters to the optimizer" begin
        model = CPRL.Optimizer()
        MOI.set(model, MOI.RawParameter("Test"), "test")
        @test model.options["Test"] == "test"
        MOI.empty!(model)
        @test MOI.is_empty(model)
        @test model.options["Test"] == "test"
    end

    @testset "Adding constrained variables" begin
        model = CPRL.Optimizer()
        MOI.add_constrained_variable(model, MOI.Interval(1, 4))
        MOI.add_constrained_variable(model, MOI.Interval(1, 4))
        MOI.add_constrained_variable(model, MOI.Interval(1, 4))
        MOI.add_constrained_variable(model, MOI.Interval(1, 4))
        @test Set(keys(model.cpmodel.variables)) == Set(["1", "2", "3", "4"])
    end

    @testset "Adding constraints" begin
        model = CPRL.Optimizer()
        MOI.add_constrained_variable(model, MOI.Interval(1, 4))
        MOI.add_constrained_variable(model, MOI.Interval(1, 4))
        MOI.add_constrained_variable(model, MOI.Interval(1, 4))
        MOI.add_constrained_variable(model, MOI.Interval(1, 4))

        # add new constraints
        MOI.add_constraint(model, MOI.SingleVariable(MOI.VariableIndex(1)), MOI.LessThan(2))
        MOI.add_constraint(model, MOI.SingleVariable(MOI.VariableIndex(2)), MOI.GreaterThan(2))
        MOI.add_constraint(model, MOI.SingleVariable(MOI.VariableIndex(4)), MOI.Interval(2, 3))

        # use fixPoint 
        CPRL.fixPoint!(model.cpmodel, model.cpmodel.constraints)

        # test if it had effect on the variables' domains
        @test model.cpmodel.variables[string(MOI.VariableIndex(1).value)].domain.max.value == 2
        @test model.cpmodel.variables[string(MOI.VariableIndex(2).value)].domain.min.value == 2
        @test model.cpmodel.variables[string(MOI.VariableIndex(4).value)].domain.min.value == 2
        @test model.cpmodel.variables[string(MOI.VariableIndex(4).value)].domain.max.value == 3

        # add some new constraints again
        MOI.add_constraint(model, MOI.SingleVariable(MOI.VariableIndex(3)), MOI.EqualTo(2))
        MOI.add_constraint(model, MOI.VectorOfVariables([MOI.VariableIndex(1), MOI.VariableIndex(3)]), CPRL.VariablesEquality(false))

        # perform another fixPoint
        CPRL.fixPoint!(model.cpmodel, model.cpmodel.constraints)

        # new bunch of test
        @test CPRL.isbound(model.cpmodel.variables[string(MOI.VariableIndex(1).value)])
        @test model.cpmodel.variables[string(MOI.VariableIndex(3).value)].domain.min.value == 2
        @test model.cpmodel.variables[string(MOI.VariableIndex(3).value)].domain.max.value == 2
    end

    @testset "JuMP interface" begin
        model = Model()
        set_optimizer(model, CPRL.Optimizer, bridge_constraints = true)
        
        @variable(model, 1 <= x[1:3] <= 4)
        @constraint(model, x[1] in CPRL.NotEqualTo(2))
        @constraint(model, x[1] in CPRL.NotEqualTo(3))
        @constraint(model, x[2] in MOI.EqualTo(4))
        @constraint(model, x[1:2] in CPRL.VariablesEquality(false))
        @constraint(model, [x[3], x[2]] in CPRL.VariablesEquality(false))
    end
end