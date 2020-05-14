@testset "model.jl" begin
    @testset "addVariable!()" begin
        trailer = CPRL.Trailer()
        x = CPRL.IntVar(2, 6, "x", trailer)
        y = CPRL.IntVar(2, 6, "y", trailer)

        model = CPRL.CPModel()

        CPRL.addVariable!(model, x)
        CPRL.addVariable!(model, y)

        @test length(model.variables) == 2

        z = CPRL.IntVar(2, 6, "y", trailer)

        @test_throws AssertionError CPRL.addVariable!(model, z)
    end

    @testset "merge!()" begin
        test1 = CPRL.CPModification("x" => [2, 3, 4],"z" => [11, 12, 13, 14, 15],"y" => [7, 8])
        test2 = CPRL.CPModification("x" => [5],"y" => [7, 8])

        CPRL.merge!(test1, test2)

        @test test1 == CPRL.CPModification("x" => [2, 3, 4, 5],"z" => [11, 12, 13, 14, 15],"y" => [7, 8, 7, 8])
    end
end