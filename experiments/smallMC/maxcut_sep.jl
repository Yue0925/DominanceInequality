
using JuMP, Gurobi


#todo :  one inequality z_u + \sum z(V) ≥ 1
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


# todo : multiple inequalities V' 
function insertion_left2(N, W, u)
    O = collect(1:N) ; deleteat!(O, u)

    ineqs = Set()


    sort!(O, by = x -> W[u, x]+W[x, u], rev = true)

    forbid = O[:]

    for p in forbid

        V = [] 

        for o in O
            if p == o continue end 

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

            if is_minimal 
                push!(ineqs, V) ; break
            end 
        end

    end


    return ineqs
end



function all_insertion_left_ineq()
    # include(fname) ; 
    ineqs = []

    for i in 1:N
        # # todo : 
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
    println(ineqs)
    return ineqs
end






function run(fname::String)
    @info "... \t $fname"
    
    folder = "./res/"
    if !isdir(folder)
        mkdir(folder)
    end


    # one_solve(fname, false )

    one_solve(fname, true )


    # mip_solve(fname)

    # folder = "./res/"* 
    inst_name = split(fname, "/")[end]

    
end


run("./instances/MaxCut_10_1")


# run("./instances/MaxCut_10_2")



# run("./instances/MaxCut_10_3")