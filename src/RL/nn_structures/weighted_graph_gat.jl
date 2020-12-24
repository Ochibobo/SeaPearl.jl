using Flux: @functor

prelu(x, α) = x > 0 ? x : α*x


"""
    EdgeFtLayer(v_in=>v_out, e_in=>e_out)

Edge Features Layers. This is used in [this article] to compute a state representation of the TSPTW.

[this article]: https://arxiv.org/abs/2006.01610

# Arguments
- `v_in`: the dimension of input features for vertices.
- `v_out`: the dimension of output features for vertices.
- `e_in`: the dimension of input features for edges.
- `e_out`: the dimension of output features for edges.
"""
struct EdgeFtLayer{T <: Real} <: MessagePassing
    W_a::AbstractMatrix{T}
    W_T::AbstractMatrix{T}
    b_T::AbstractVector{T}
    W_e::AbstractMatrix{T}
    W_ee::AbstractMatrix{T}
    prelu_α::T
end

function EdgeFtLayer(;v_dim::Pair{<:Integer,<:Integer}, e_dim::Pair{<:Integer,<:Integer}, heads::Integer=1,
                 concat::Bool=true, negative_slope::Real=0.2, init=glorot_uniform,
                 bias::Bool=true, T::DataType=Float32)

    # Used to compute node features
    W_a = T.(init(v_dim[2], 2 * v_dim[1] + e_dim[1]))
    W_T = T.(init(v_dim[2], 2 * v_dim[1] + e_dim[1]))
    b_T = bias ? T.(init(v_dim[2])) : zeros(T, v_dim[2])

    # Used to compute edge features
    W_e = T.(init(e_dim[2], v_dim[1]))
    W_ee = T.(init(e_dim[2], e_dim[1]))


    EdgeFtLayer(W_a, W_T, b_T, W_e, W_ee, init(1)[1])
end

@functor EdgeFtLayer


function (g::EdgeFtLayer)(fg::FeaturedGraph)
    Zygote.ignore() do
        GraphSignals.check_num_node(graph(fg), node_feature(fg))
    end
    GeometricFlux.propagate(g, fg, :add)
end

function GeometricFlux.message(l::EdgeFtLayer, x_i::AbstractVector, x_j::AbstractVector, e_ij::AbstractVector)
    x = vcat(x_i, e_ij, x_j)
    attention_logits = prelu.(l.W_a*x, l.prelu_α)
    unattended_node_features = l.W_T*x

    return vcat(attention_logits, unattended_node_features)
end

function GeometricFlux.update_batch_edge(g::EdgeFtLayer, adj, E::AbstractMatrix, X::AbstractMatrix)
    n = size(adj, 1)
    edge_idx = GeometricFlux.edge_index_table(adj)
    hcat([GeometricFlux.apply_batch_message(g, i, adj[i], edge_idx, E, X) for i in 1:n]...)
end

update_batch_edge(g::EdgeFtLayer, adj, E::AbstractMatrix, X::AbstractMatrix, u) = update_batch_edge(g, adj, E, X)

function GeometricFlux.apply_batch_message(g::EdgeFtLayer, i, js, edge_idx, E::AbstractMatrix, X::AbstractMatrix)
    mailbox = hcat([GeometricFlux.message(g, GeometricFlux.get_feature(X, i), GeometricFlux.get_feature(X, j), E[:, edge_idx[(i, j)]]) for j = js]...)

    # Get each part of the message separately
    out_channel_v = size(g.W_a, 1)
    attention_logits = mailbox[1:out_channel_v, :]
    unattended_node_features = mailbox[out_channel_v+1:end, :]

    # Apply the attention mechanism
    attention = Flux.softmax(attention_logits, dims=2)
    final_messages = attention .* unattended_node_features

    # Copy the bias over each neighbor
    bias_cloned = hcat([g.b_T/length(js) for j = js]...)

    final_messages + bias_cloned
end


function Base.show(io::IO, l::EdgeFtLayer)
    in_channel_v = size(l.W_e, 2)
    out_channel_v = size(l.W_a, 1)
    in_channel_e = size(l.W_ee, 2)
    out_channel_e = size(l.W_ee, 1)
    print(io, "EdgeFtLayer(")
    print(io, "), v_dim=", in_channel, "=>", out_channel)
    print(io, ", PReLU(α=", l.prelu_α)
    print(io, "))")
end

