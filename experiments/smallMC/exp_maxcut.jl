
using JuMP, Gurobi, CPLEX

"""
    x_u + x(V) <= |V| + x_v + x(V_)
Return : tuple (u, V, v, V_)
"""
function swap(N, W, u, v)
    O = collect(1:N) ; deleteat!(O, [u,v])

    V = [] ; V_ = []

    sort!(O, by = x -> abs( W[u, x]+W[x, u] - W[v, x]-W[x, v] ), rev = true)

    for o in O
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
            return (u, V, v, V_)
        end
    end
      
    return nothing
end


# #todo :  one inequality z_u + \sum z(V) ≥ 1
# function insertion_left(N, W, u)
#     O = collect(1:N) ; deleteat!(O, u)

#     V = [] 

#     sort!(O, by = x -> W[u, x]+W[x, u], rev = true)
    
#     for o in O
#         push!(V, o)

#         V_ =collect(1:N) ; deleteat!(V_, sort([V; u]))

#         weight_V = sum(W[v, u]+W[u,v] for v in V)
#         weight_V_ = sum(W[v, u]+W[u,v] for v in V_)

#         is_minimal = false 

#         if weight_V > weight_V_

#             is_minimal = true
#             for v in V
#                 if weight_V - (W[u,v]+W[v,u]) ≥ weight_V_ + (W[u,v]+W[v,u])
#                     is_minimal = false ; break
#                 end
#             end
#         end

#         if is_minimal return V end 
#     end
#     return []
# end


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


# todo : multiple inequalities V' 
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
return vector of tuples 
"""
function all_swap_ineq(fname)
    include(fname)
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

    println(ineqs)
    return ineqs
end


function all_insertion_left_ineq(fname)
    include(fname) 

    # # todo : uncomment for BiqMac instances 
    # W = readBiqMac(fname)
    # N = size(W, 1)

    # W = parserPW(fname)
    # N = size(W, 1)
    
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



using LinearAlgebra, CSDP

# function readBiqMac(fname)
#     f = open(fname)

#     line = readline(f)

#     n = parse(Int64, split(line, " ")[1] ) ; l = parse(Int64, split(line, " ")[2] ) 
#     W = zeros(n, n)

#     for i in 1:l
#         line = readline(f)
#         v = split(line, " ")

#         i = parse(Int64, v[1]) ; j = parse(Int64, v[2] ) 
#         w = parse(Float64, v[3] ) 
#         W[i,j] = w
#     end

#     close(f)

#     # println(W)

#     # for i in 1:N 
#     #     for j in 1:N 
#     #         println("i : $i , j : $j \t $(W[i,j])")
#     #     end
#     # end

#     for i in 1:n
#         for j in 1:n
#             if i==j continue end 
#             if W[i,j] != 0.0 && W[j,i] != W[i, j]
#                 error("directed edges !! ")
#             end
#         end
        
#     end
#     return W
# end

# function parserPW(fname)
#     f = open(fname)

#     line = readline(f)

#     n = parse(Int64, split(line, " ")[1] ) ; l = parse(Int64, split(line, " ")[2] ) 
#     W = zeros(n, n)

#     for i in 1:l
#         line = readline(f)
#         v = split(line, " ")

#         i = parse(Int64, v[1]) ; j = parse(Int64, v[2] ) 
#         w = parse(Float64, v[3] ) 
#         W[i,j] = w
#     end

#     close(f)

#     # println(W)

#     # for i in 1:N 
#     #     for j in 1:N 
#     #         println("i : $i , j : $j \t $(W[i,j])")
#     #     end
#     # end

#     for i in 1:n
#         for j in 1:n
#             if i==j continue end 
#             if W[i,j] != 0.0 && W[j,i] != 0.0
#                 error("directed edges !! ")
#             end
#         end
        
#     end
#     return W
# end


"""
Return the convexification coefficients Q and c. 
"""
function csdp_QCR(fname; cut=false)
    
    include(fname)

    # # todo : uncomment for BiqMac instances 
    # W = readBiqMac(fname)
    # N = size(W, 1)

    # W = parserPW(fname)
    # N = size(W, 1)

    model = Model(CSDP.Optimizer)
    JuMP.set_silent(model)


    Q = zeros(N, N) ; c=zeros(N)
    for i in 1:N
        for j in 1:N
            c[i] +=  W[i,j]
            c[j] +=  W[i,j]

            Q[i,j] += -2 * W[i,j]     
        end
    end

    @variable(model, 0<= x[1:N] )
    @variable(model, X[1:N, 1:N], Symmetric)
    @constraint(model, [1 x'; x X] in PSDCone())

    if cut
        ineqs = all_insertion_left_ineq(fname) #; nb_dom_cuts += length(ineqs) *2
        for inq in ineqs
            @constraint(model, sum(x[i] for i in inq) ≥ 1)

            @constraint(model, sum(x[i] for i in inq) ≤ length(inq)-1 )
        end
    end


    @objective(model, Min, tr(-Q * X) - c'*x )

    # f = sum( W[i,j] * ( x[i] -X[i,j] + x[j] - X[j,i] ) for i in 1:N for j in 1:N )
    # @objective(model, Min, -f)
    # println(f)


    con5 = @constraint(model, [i in 1:N], X[i,i] - x[i] == 0)


    optimize!(model)
    solved_time = solve_time(model) 
    println("QCR time : ", round(solved_time, digits = 4))

    if termination_status(model)== OPTIMAL
        sol = value.(x)
        obj = objective_value(model)

        println("obj = ", obj) # , " \n x = ", sol, "\n X = ", value.(X))

        ϕ5 = dual.(con5)

        # println("ϕ = ", ϕ)

        S = -Q 
        for i in 1:N
            S[i,i] -= ϕ5[i]
        end

        println("S is PSD ? ", minimum(eigvals(S))>=0.0 ) 


        if minimum(eigvals(S))>=0.0 
            return -ϕ5
        else 
            error("QCR method errors ! ")
        end

    end

    return zeros(N)
end


function QP_solve(fname ; grb_solver=true, QCR=false)
    include(fname)

    # # todo : uncomment for BiqMac instances 
    # W = readBiqMac(fname)
    # N = size(W, 1)

    # W = parserPW(fname)
    # N = size(W, 1)

    if grb_solver 
        model = Model(Gurobi.Optimizer)
    else
        model = Model(CPLEX.Optimizer)
    end 
    # JuMP.set_silent(model)

    @variable(model, x[1:N], Bin )

    
    if QCR
        λ = csdp_QCR(fname)
        f = sum( W[i,j] * (x[i]*(1-x[j]) + x[j]*(1-x[i]) ) for i in 1:N for j in 1:N) - 
                            sum(λ[i] * (x[i]^2 - x[i] ) for i in 1:N)
        @objective(model, Min, -f)
    else
        @objective(model, Max, sum( W[i,j] * (x[i]*(1-x[j]) + x[j]*(1-x[i]) ) for i in 1:N for j in 1:N) )
    end

    MOI.set(model, MOI.NumberOfThreads(), 1) # todo 

    optimize!(model)

   if termination_status(model)== OPTIMAL
    sol = value.(x)
    obj = objective_value(model)

    println("obj = ", obj, " \n x = ", sol)
    # fout = open(fname, "a")
    # println(fout, "opt_val = ", round(obj, digits = 4))
    # close(fout)
   else
        error("no OPT sol ", fname)
   end

end


function one_solve(fname; cut=true, grb_solver=true, QCR=false , root=false )

    println(" dominance cuts ? ", cut, "\n grb solver ? ", grb_solver, "\n QCR ? ", QCR, "\n root limit ? ", root)

    include(fname)


    # # todo : uncomment for BiqMac instances 
    # W = readBiqMac(fname)
    # N = size(W, 1)

    # W = parserPW(fname)
    # N = size(W, 1)

    if grb_solver 
        model = Model(Gurobi.Optimizer) 
    else
        model = Model(CPLEX.Optimizer) 
    end

    # JuMP.set_silent(model)
    # set_optimizer_attribute(model, "LogFile", fname)

 
    @variable(model, x[1:N], Bin )

    if QCR

        Q = zeros(N, N) ; c=zeros(N)
        for i in 1:N
            for j in 1:N
                c[i] +=  W[i,j]
                c[j] +=  W[i,j]

                Q[i,j] += -2 * W[i,j]     
            end
        end

        λ = csdp_QCR(fname)
        f = x'*(-Q)*x -c'*x + sum((λ[i]+0.00001) * (x[i]^2 - x[i] ) for i in 1:N)
        @objective(model, Min, f)
        # println(f)
    else
        f = sum( W[i,j] * (x[i]*(1-x[j]) + x[j]*(1-x[i]) ) for i in 1:N for j in 1:N) 
        @objective(model, Max, f)
        # println(f)
    end

  
    nb_dom_cuts=0

    # # todo brut force tout ineq 1) 
    if cut
        ineqs = all_insertion_left_ineq(fname) ; nb_dom_cuts += length(ineqs) *2
        for inq in ineqs
            @constraint(model, sum(x[i] for i in inq) ≥ 1)

            @constraint(model, sum(x[i] for i in inq) ≤ length(inq)-1 )
        end

        println("\n\n----------------------swap inequalities\n")
        ineqs = all_swap_ineq(fname) ;  nb_dom_cuts += length(ineqs) *2

        for inq in ineqs
            u = inq[1]; V = inq[2] ; v = inq[3]; V_ = inq[4]
            @constraint(model, x[u] + sum(x[t] for t in V) ≤ length(V) + x[v] + sum(x[t] for t in V_) )

            @constraint(model, x[v] + sum(x[t] for t in V_) ≤ length(V_) + x[u] + sum(x[t] for t in V) )
        end


    end
    

    #todo :  Gurobi parameters 
    if grb_solver
        set_attribute(model, "Presolve", 0)
        set_attribute(model, "AggFill", -1)
        set_attribute(model, "Aggregate", 0)
        set_attribute(model, "Heuristics", 0)
        set_attribute(model, "LPWarmStart", 0)
        set_attribute(model, "NLPHeur", 0)
        set_attribute(model, "NoRelHeurTime", 0)
        set_attribute(model, "PreCrush", 0)
        set_attribute(model, "PreDepRow", 0)
        set_attribute(model, "PreDual", 0)
        set_attribute(model, "PrePasses", -1)
        set_attribute(model, "RINS", 0)
        set_attribute(model, "Symmetry", 0)
        # set_attribute(model, "PSDCuts", 0)

        set_attribute(model, "PreQLinearize", 0)

        # if QCR
            set_attribute(model, "NonConvex", 0)
        # end
    else
    
        # todo : turn off parameters 
        set_optimizer_attribute(model, "CPX_PARAM_CLIQUES", -1)
        set_optimizer_attribute(model, "CPXPARAM_MIP_Cuts_LiftProj", -1)
        set_optimizer_attribute(model, "CPX_PARAM_LANDPCUTS", -1)
        set_optimizer_attribute(model, "CPX_PARAM_COVERS", -1)
        set_optimizer_attribute(model, "CPX_PARAM_DISJCUTS", -1)
        set_optimizer_attribute(model, "CPX_PARAM_FLOWCOVERS", -1)
        set_optimizer_attribute(model, "CPX_PARAM_FLOWPATHS", -1)
        set_optimizer_attribute(model, "CPX_PARAM_FRACCUTS", -1)
        set_optimizer_attribute(model, "CPX_PARAM_GUBCOVERS", -1)
        set_optimizer_attribute(model, "CPX_PARAM_ZEROHALFCUTS", -1)
        set_optimizer_attribute(model, "CPX_PARAM_MIRCUTS", -1)
        set_optimizer_attribute(model, "CPX_PARAM_IMPLBD", -1)
        set_optimizer_attribute(model, "CPX_PARAM_CUTPASS", -1)

        set_optimizer_attribute(model, "CPX_PARAM_FPHEUR", -1)
        set_optimizer_attribute(model, "CPX_PARAM_PROBE", -1)
        set_optimizer_attribute(model, "CPX_PARAM_HEURFREQ", -1)
        set_optimizer_attribute(model, "CPX_PARAM_RINSHEUR", -1)

        set_optimizer_attribute(model, "CPX_PARAM_QPMAKEPSDIND", 0)

        set_optimizer_attribute(model, "CPX_PARAM_QTOLININD", 0)    # todo !

        # set_optimizer_attribute(model, "CPX_PARAM_PREIND", 0)
        set_optimizer_attribute(model, "CPX_PARAM_AGGIND", 0)
        set_optimizer_attribute(model, "CPX_PARAM_RELAXPREIND", 0)
        set_optimizer_attribute(model, "CPX_PARAM_PREPASS", 0)
        set_optimizer_attribute(model, "CPX_PARAM_REPEATPRESOLVE", 0)
        set_optimizer_attribute(model, "CPX_PARAM_BNDSTRENIND", 0)
        set_optimizer_attribute(model, "CPX_PARAM_COEREDIND", 0)
        # set_optimizer_attribute(model, "CPX_PARAM_REDUCE", 0)
        set_optimizer_attribute(model, "CPXPARAM_Preprocessing_Symmetry", 0)

    end


    if root
        set_optimizer_attribute(model, "NodeLimit", 1)
    end 

    MOI.set(model, MOI.NumberOfThreads(), 1) # todo 

    # MOI.set(model, Gurobi.CallbackFunction(), my_callback_function)


    optimize!(model)

    solved_time = solve_time(model) 
    explored_nodes = node_count(model)

    println("solved_time = ", solved_time)
    println("explored_nodes = ", explored_nodes)


    obj = 0.0
    opt = termination_status(model)== OPTIMAL

    if is_solved_and_feasible(model)
        sol = value.(x)
        gap = relative_gap(model) 

        # if abs(gap) <= 0.001
            obj = objective_value(model)
            println( "gap = $(gap) \t obj = $obj \t x = $sol \t nb_dom_cuts=$nb_dom_cuts" )
        # end

    else

        obj = objective_bound(model)
        # obj = sum( sum(W[i,j] * (best_solution[i]*(1-best_solution[j]) + 
        #                             best_solution[j]*(1-best_solution[i])) for j in 1:N) for i in 1:N)
        
        println( " obj = $obj \t nb_dom_cuts=$nb_dom_cuts" )        # \t x = $best_solution 

    end

    println(" ----------------------------- \n\n")

    # fout = open(fname, "a")
    # println(fout, "opt = $opt")
    # println(fout, "obj = ", round(obj, digits=4))

    # if cut println(fout, "nb_dom_cuts = $nb_dom_cuts") end 

    # println(fout, "solved_time = ", round(solved_time, digits=4))
    # close(fout)

    return obj,opt
end


function run(fname::String)
    @info "... \t $fname"
    
    folder = "./res/"
    if !isdir(folder)
        mkdir(folder)
    end


    one_solve(fname, cut=true, grb_solver = true, QCR=false, root=false )

    # one_solve(fname, cut = true, grb_solver = true , QCR = false)


    # one_solve(fname, cut=false, grb_solver = true, QCR=true )
    # one_solve(fname, cut=false, grb_solver = true, QCR=false )


    # one_solve(fname, cut = true, grb_solver = true , QCR = true)


    # QP_solve(fname, grb_solver=true, QCR=false)
    # QP_solve(fname, grb_solver=true, QCR=true)

    # folder = "./res/"* 
    # inst_name = split(fname, "/")[end]

end


fname = "./instances/MaxCut_10_1"
run(fname)

# run(fname)


# csdp_QCR("./instances/MaxCut_10_1")

# csdp_QCR("./instances/BigMaq_10")
# readBiqMac("./instances/BigMaq_10")

# run("./instances/MaxCut_10_2")



# run("./instances/MaxCut_10_3")

