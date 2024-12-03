
using JuMP, Gurobi



global model
global best_solution = []


function my_callback_function(cb_data, cb_where)
    global model
    global best_solution

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

        valueP = Ref{Cdouble}()
        GRBcbget(cb_data, cb_where, GRB_CB_MIPSOL_OBJBND, valueP)
        
        # if valueP[] < best_value
            best_value = valueP[]
            Gurobi.load_callback_variable_primal(cb_data, cb_where)
            best_solution = callback_value.(cb_data, all_variables(model))
            # @info "New upper bound: $best_value   best_solution = $best_solution"
        # end    
    # end
end


function mip_solve(fname)
    include(fname)

    model = Model(Gurobi.Optimizer) # ; JuMP.set_silent(model)

    @variable(model, x[1:N], Bin )
    @objective(model, Max, sum( sum(W[i,j] * (x[i]*(1-x[j]) + x[j]*(1-x[i])) for j in 1:N) for i in 1:N) )


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

function one_solve(fname, cut::Bool )
    global best_solution = []

    include(fname)

    global model = Model(Gurobi.Optimizer)  #; JuMP.set_silent(model)
    # set_optimizer_attribute(model, "LogFile", fname)

 
    @variable(model, x[1:N], Bin )
    @objective(model, Max, sum( sum(W[i,j] * (x[i]*(1-x[j]) + x[j]*(1-x[i])) for j in 1:N) for i in 1:N) )


    
    nb_dom_cuts=0
    # # # todo brut force tout ineq 1) 
    # if cut
    #     ineqs = all_dominance_ineq(inst) ; nb_dom_cuts = length(ineqs)
    #     for inq in ineqs
    #         @constraint(model, x[inq[1]] ≤ sum( x[i] for i in inq[2:end]) )
    #     end
    # end
    

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



    set_optimizer_attribute(model, "NodeLimit", 1)

    MOI.set(model, MOI.NumberOfThreads(), 1) # todo 
    MOI.set(model, Gurobi.CallbackFunction(), my_callback_function)


    optimize!(model)
    solved_time = solve_time(model) 


    obj = nothing
    opt = termination_status(model)== OPTIMAL

    if is_solved_and_feasible(model)
        sol = value.(x)
        gap = relative_gap(model) 

        if gap == 0.0
            obj = objective_value(model)
            println( "gap = $(gap) \t obj = $obj \t x = $sol \t nb_dom_cuts=$nb_dom_cuts" )
        end

    elseif length(best_solution) >0

        obj = sum( sum(W[i,j] * (best_solution[i]*(1-best_solution[j]) + 
                                    best_solution[j]*(1-best_solution[i])) for j in 1:N) for i in 1:N)
        println( " obj = $obj \t x = $best_solution \t nb_dom_cuts=$nb_dom_cuts" )
    else
        @warn "no sol found in callback ! "
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
    
    folder = "./res/"
    if !isdir(folder)
        mkdir(folder)
    end

    one_solve(fname, false )

    mip_solve(fname)

    # folder = "./res/"* 
    inst_name = split(fname, "/")[end]

    
end


run("./instances/MaxCut_10_1")