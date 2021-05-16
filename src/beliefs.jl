struct POWNodeBelief{S,A,O,P}
    model::P
    a::A # may be needed in push_weighted! and since a is constant for a node, we store it
    o::O
    dist::CategoricalVector{Tuple{S,Float64}}
    

    POWNodeBelief{S,A,O,P}(m,a,o,d) where {S,A,O,P} = new(m,a,o,d)
    function POWNodeBelief{S, A, O, P}(m::P, s::S, a::A, sp::S, o::O, r) where {S, A, O, P}
        cv = CategoricalVector{Tuple{S,Float64}}((sp, convert(Float64, r)),
                                                 1)
        new(m, a, o, cv)#initial
        
    end
end

function POWNodeBelief(model::POMDP{S,A,O}, s::S, a::A, sp::S, o::O, r) where {S,A,O}
    POWNodeBelief{S,A,O,typeof(model)}(model, s, a, sp, o, r)
end

rand(rng::AbstractRNG, b::POWNodeBelief) = rand(rng, b.dist)
state_mean(b::POWNodeBelief) = first_mean(b.dist)
POMDPs.currentobs(b::POWNodeBelief) = b.o
POMDPs.history(b::POWNodeBelief) = tuple((a=b.a, o=b.o))


struct POWNodeFilter end

belief_type(::Type{POWNodeFilter}, ::Type{P}) where {P<:POMDP} = POWNodeBelief{statetype(P), actiontype(P), obstype(P), P}

init_node_sr_belief(::POWNodeFilter, p::POMDP, s, a, sp, o, r) = POWNodeBelief(p, s, a, sp, o, r)

function push_weighted!(b::POWNodeBelief, ::POWNodeFilter, s, sp, r)
    w = 1
    insert!(b.dist, (sp, convert(Float64, r)), w)
end
"""
原来的r是在o下执行a得到的r，因为我们现在需要把s'加入到其他o分支中，所以这个r也应该变成在其他o下执行a得到的r，但是目前来说，我不知道应该如何实现，所以暂且不实现
"""
struct StateBelief{SRB<:POWNodeBelief}
    sr_belief::SRB
end

rand(rng::AbstractRNG, b::StateBelief) = first(rand(rng, b.sr_belief))
mean(b::StateBelief) = state_mean(b.sr_belief)
POMDPs.currentobs(b::StateBelief) = currentobs(b.sr_belief)
POMDPs.history(b::StateBelief) = history(b.sr_belief)
