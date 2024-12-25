
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

global model
global best_solution = []
global nb_dom_cuts=0


function my_callback_function(cb_data, cb_where)
    global model
    global best_solution
    global nb_dom_cuts

    if cb_where != GRB_CB_MIPNODE # cb_where != GRB_CB_MIPSOL &&
        return
    end

    # You can query a callback attribute using GRBcbget
    if cb_where == GRB_CB_MIPNODE
        valueP = Ref{Cint}()
        GRBcbget(cb_data, cb_where, GRB_CB_MIPNODE_STATUS, valueP)
        if valueP[] != GRB_OPTIMAL
            return  # Solution is something other than optimal.
        end
    end

    # if callback_node_status(cb_data, model) == MOI.CALLBACK_NODE_STATUS_FRACTIONAL

        valueP = Ref{Cdouble}() ; x = all_variables(model)
        GRBcbget(cb_data, cb_where, GRB_CB_MIPSOL_OBJBND, valueP)
        
        # if valueP[] < best_value
            best_value = valueP[]
            Gurobi.load_callback_variable_primal(cb_data, cb_where)
            best_solution = callback_value.(cb_data, x)
            # @info "New upper bound: $best_value   best_solution = $best_solution"
        # end  
        
        # todo : no matter what insert all inequalities
        ineqs = all_insertion_left_ineq() ; nb_dom_cuts += length(ineqs) *2
        for inq in ineqs
            con = @build_constraint(sum(x[i] for i in inq) ≥ 1)
            MOI.submit(model, MOI.LazyConstraint(cb_data), con)

            con = @build_constraint(sum(x[i] for i in inq) ≤ length(inq)-1 )
            MOI.submit(model, MOI.LazyConstraint(cb_data), con)

        end


    # end
end


function one_solve(fname, cut::Bool)
    global best_solution = []

    include(fname)

    global model = Model(Gurobi.Optimizer)  #; JuMP.set_silent(model)
    # set_optimizer_attribute(model, "LogFile", fname)

 
    @variable(model, x[1:N], Bin )
    @objective(model, Max, sum( sum(W[i,j] * (x[i]*(1-x[j]) + x[j]*(1-x[i])) for j in 1:N) for i in 1:N) )


    global nb_dom_cuts=0

    # # todo cut in separation 
    if cut

        MOI.set(model, MOI.NumberOfThreads(), 1) # todo 
        MOI.set(model, MOI.RawOptimizerAttribute("LazyConstraints"), 1)
        MOI.set(model, Gurobi.CallbackFunction(), my_callback_function)
    end
    
    
    
    #todo :  Gurobi parameters 
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



    # set_optimizer_attribute(model, "NodeLimit", 1)

    optimize!(model)
    solved_time = solve_time(model) 

    # set_optimizer_attribute(model, "DisplayInterval", 1)

    obj = 0.0
    opt = termination_status(model)== OPTIMAL

    if is_solved_and_feasible(model)
        sol = value.(x)
        gap = relative_gap(model) 

        if gap == 0.0
            obj = objective_value(model)
            println( "gap = $(gap) \t obj = $obj \t x = $sol \t nb_dom_cuts=$nb_dom_cuts" )
        end

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


    # one_solve(fname, false )

    one_solve(fname, true )


    # mip_solve(fname)

    # folder = "./res/"* 
    inst_name = split(fname, "/")[end]

    
end


run("./instances/MaxCut_10_1")


# run("./instances/MaxCut_10_2")



# run("./instances/MaxCut_10_3")