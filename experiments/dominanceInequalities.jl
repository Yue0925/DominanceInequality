"""
  one inequality z_u + sum z(V) ≥ 1    
"""
# todo : verify negative coefficients
function insertion_left(N, W, u)
    O = collect(1:N) ; deleteat!(O, u)

    V = [] 

    sort!(O, by = x -> W[u, x]+W[x, u], rev = true)
    
    for o in O
        push!(V, o)

        V_ =collect(1:N) ; deleteat!(V_, sort([V; u]))

        weight_V = sum(W[v, u]+W[u,v] for v in V)
        weight_V_ = sum(W[v, u]+W[u,v] for v in V_)

        is_minimal = false 

        if weight_V > weight_V_

            is_minimal = true
            for v in V
                if weight_V - (W[u,v]+W[v,u]) ≥ weight_V_ + (W[u,v]+W[v,u])
                    is_minimal = false ; break
                end
            end
        end

        if is_minimal return V end 
    end
    return []
end

"""
    multiple inequalities V' 
"""
function insertion_left2(N, W, u)
    O = collect(1:N) ; deleteat!(O, u)

    ineqs = Set()

    sort!(O, by = x -> W[u, x]+W[x, u], rev = true)

    forbid = [-1 ; O[:] ]

    for p in forbid

        V = [] 

        for o in O
            if p == o continue end 

            push!(V, o)

            V_ =collect(1:N) ; deleteat!(V_, sort([V; u]))

            # negative edges case
            V_neg = [] ; idx = 0 ; delete_idx = []
            for i in V_
                idx += 1
                if W[u, i] + W[i,u] < 0.0 
                    push!(V_neg, i) ; push!(delete_idx, idx)
                end
            end
            if length(delete_idx) > 0 deleteat!(V_, delete_idx) end 

            weight_V = length(V)>0 ? sum(W[v, u]+W[u,v] for v in V) : 0.0
            weight_V_ =  length(V_)>0 ? sum(W[v, u]+W[u,v] for v in V_) : 0.0

            if length(V_neg)>0
                weight_V += sum(W[v, u]+W[u,v] for v in V_neg)
            end

            is_minimal = false 

            if weight_V > weight_V_

                is_minimal = true
                for v in V
                    if weight_V - (W[u,v]+W[v,u]) ≥ weight_V_ + (W[u,v]+W[v,u])
                        is_minimal = false ; break
                    end
                end
            end

            if is_minimal 
                push!(ineqs, V) ; break 
            end 
        end
    end
    return ineqs
end



"""
    x_u + x(V) <= |V| + x_v + x(V_)
Return : Set of tuple (u, V, v, V_)
"""
function swap2(N, W, u, v)
    O = collect(1:N) ; deleteat!(O, [u,v])
    ineqs = Set()

    sort!(O, by = x -> abs( W[u, x]+W[x, u] - W[v, x]-W[x, v] ), rev = true)

    forbid = [-1 ; O[:] ]

    for p in forbid
        V = [] ; V_ = []

        for o in O
            if p == o continue end 

            if W[u, o]+W[o, u] - W[v, o] - W[o, v] > W[v, o]+W[o, v] - W[u, o]-W[o, u]
                push!(V,o)

            elseif W[u, o]+W[o, u] - W[v, o] - W[o, v] < W[v, o]+W[o, v] - W[u, o]-W[o, u]
                push!(V_, o)
            else
                length(V)<length(V_) ? push!(V,o) : push!(V_, o)
            end

            # objective variation
            Δ = length(V)>0 ? sum(W[t, u]+W[u,t] for t in V) : 0 + 
                length(V_)>0 ? sum(W[v, t]+W[t,v] for t in V_) : 0 - 
                length(V)>0 ? sum(W[t, v]+W[v,t] for t in V) : 0 - 
                length(V_)>0 ? sum(W[t, u]+W[u,t] for t in V_) : 0

            if Δ <= 0
                continue
            end

            # stop criteria
            V_tilde = collect(1:N) ; deleteat!(V_tilde, sort(collect(Set([V; V_; u ; v]))))

            if Δ > (length(V_tilde)>0 ? sum(abs(W[t, u]+W[u,t]-W[t, v]-W[v,t]) for t in V_tilde) : 0 )
                # todo : find a valid inequality 
                push!(ineqs, (u, V, v, V_) )
                break
            end

        end
    end

    return ineqs
end

function all_insertion_left_ineq(N, W)
    ineqs = []

    for i in 1:N
        # V = insertion_left(N, W, i)
        # if length(V) > 0 
        #     push!(ineqs, [i; V])
        # end

        all_V = insertion_left2(N, W, i)
        if length(all_V) > 0 
            for V in all_V
                push!(ineqs, [i; V])
            end
        end
    end

    # println(ineqs)
    
    return ineqs
end


"""
return vector of tuples 
"""
function all_swap_ineq(N, W)
    ineqs = []

    for u in 1:N-1
        for v in u+1:N
            # # todo : 
            # inq = swap(N, W, u, v)
            # if inq != nothing
            #     push!(ineqs, inq)
            # end

            for inq in swap2(N, W, u, v)
                push!(ineqs, inq)
            end
        end
    end

    # println(ineqs)
    return ineqs
end
