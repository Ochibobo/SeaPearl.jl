using LinearAlgebra

export CPGraphSpace

mutable struct CPGraph
    featuredgraph::GeometricFlux.FeaturedGraph
    variable_id::Int64
end

"""
    CPGraph(cplayergraph::CPLayerGraph, x::AbstractIntVar)

Construct a CPGraph from the CPLayerGraph and the variable we want to branch on. 
Here we will define how the node feature will look like. Thus, it might be transformed later.
"""
function CPGraph(g::CPLayerGraph, x::AbstractIntVar)
    sparse_adj = LightGraphs.LinAlg.adjacency_matrix(g)
    # temporary use of a one hot encoder for each node. 
    feature = Matrix{Float32}(I, nv(g), nv(g))
    variable_id = index(g, VariableVertex(x))
    
    CPGraph(GeometricFlux.FeaturedGraph(sparse_adj, feature), variable_id)
end

"""
    CPGraph(cplayergraph::CPLayerGraph, var_id::Int64)

Construct a CPGraph from the CPLayerGraph and the variable we want to branch on. 
Here we will define how the node feature will look like. Thus, it might be transformed later.
"""
function CPGraph(g::CPLayerGraph, var_id::Int64)
    sparse_adj = LightGraphs.LinAlg.adjacency_matrix(g)
    # temporary use of a one hot encoder for each node. 
    feature = Matrix{Float32}(I, nv(g), nv(g))
    
    CPGraph(GeometricFlux.FeaturedGraph(sparse_adj, feature), var_id)
end

#Base.ndims(g::CPGraph) = ndims(feature(g.featuredgraph))
#Base.size(g::CPGraph) = size(feature(g.featuredgraph))
#Base.reshape(g::CPGraph, t) = FeaturedGraph(graph(g.graoh), reshape(feature(g.featuredgraph), t))

"""
    update!(cpgraph::CPGraph, g::CPLayerGraph, x::AbstractIntVar)

Update a CPGraph instance thanks to a new CPLayerGraph and a new Variable. 
The only thing that stay identic is basically the feature matrix.

---------- WARNING : 
At the moment, we are using GeometricFlux.FeaturedGraph, which is immutable, so
we could change the pointer ref or change elements after elements in the sparse 
adjacency matrix. But in order to get the things done quickly, we will start by ignoring 
the update!() function and we will create a new FeaturedGraph when we want to update
CPGraph.
"""
function update!(cpgraph::CPGraph, g::CPLayerGraph, x::AbstractIntVar)
    cpgraph.variable_id = index(g, VariableVertex(x))

    feature = cpgraph.featuredgraph.feature[]
    sparse_adj = LightGraphs.LinAlg.adjacency_matrix(g)

    cpgraph.featuredgraph = GeometricFlux.FeaturedGraph(sparse_adj, feature)
    nothing
end
