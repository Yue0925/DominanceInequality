

using JuMP, Gurobi, CPLEX

include("dominanceInequalities.jl")
include("QCR_csdp.jl")



function one_solve(N, W, logname; qcr_cut = false, cut=false, grb_solver=true, QCR=false , QCR2 = false, root=false )

    println(" dominance cuts ? ", cut, "\n grb solver ? ", grb_solver, "\n QCR ? ", QCR, "\n root limit ? ", root)
    fout = open(logname, "a")
    nb_dom_cuts=0

    if grb_solver 
        model = Model(Gurobi.Optimizer) 
        set_time_limit_sec(model, 1800.0)  # todo : 
    else
        model = direct_model(CPLEX.Optimizer())
        set_optimizer_attribute(model, "CPXPARAM_TimeLimit", 1800) # todo : 
    end

    if root 
        JuMP.set_silent(model) 
    else
        if grb_solver
            set_optimizer_attribute(model, "LogFile", logname)
        else
            CPXsetlogfilename(backend(model).env, logname, "a")
            set_optimizer_attribute(model, "CPX_PARAM_CLONELOG", -1)
        end
    end 
    
 
    @variable(model, x[1:N], Bin )

    # -----------------------------------------------
    # -------------------- QCR 1
    if QCR
        Q = zeros(N, N) ; c=zeros(N)
        for i in 1:N
            for j in 1:N
                c[i] +=  W[i,j]
                c[j] +=  W[i,j]

                Q[i,j] += -2 * W[i,j]     
            end
        end

        λ, QCR_time, nb_dom_cuts = csdp_QCR(W, N, cut=qcr_cut)
        if !root println(fout, "QCR_time = $QCR_time") end 
        qcr_cut ? println(fout, "nb_dom_cuts = $nb_dom_cuts") : nothing

        f = x'*(-Q)*x -c'*x + sum( (λ[i]+0.00001) * (x[i]^2 - x[i] ) for i in 1:N)
        @objective(model, Min, f)


    # ------------------------------------------------------------
    # ---------------------- QCR 2
    elseif QCR2
        @variable(model, z[1:N, 1:N] ≥ 0 ) 
        @constraint(model, [i in 1:N, j in 1:N], z[i,j] ≤ x[i]) ; @constraint(model, [i in 1:N, j in 1:N], z[i,j] ≤ x[j])
        @constraint(model, [i in 1:N, j in 1:N], z[i,j] ≥ x[i] + x[j] - 1 )

        Q = zeros(N, N) ; c=zeros(N)
        for i in 1:N
            for j in 1:N
                c[i] +=  W[i,j]
                c[j] +=  W[i,j]

                Q[i,j] += -2 * W[i,j]     
            end
        end

        λ, Γ, QCR_time, nb_dom_cuts = csdp_QCR2(W, N, cut=qcr_cut)
        if !root println(fout, "QCR_time = $QCR_time") end 
        qcr_cut ? println(fout, "nb_dom_cuts = $nb_dom_cuts") : nothing

        f = x'*(-Q)*x -c'*x + sum((λ[i]+0.00001) * (x[i]^2 - x[i] ) for i in 1:N) +
                    sum(Γ[i,j] * (z[i,j] - x[i]*x[j]) for i in 1:N for j in 1:N)
        @objective(model, Min, f)


    else
        f = sum( W[i,j] * (x[i]*(1-x[j]) + x[j]*(1-x[i]) ) for i in 1:N for j in 1:N) 
        @objective(model, Max, f)
    end

    

    nb_dom_cuts=0
    if cut
        ineqs = all_insertion_left_ineq(N, W) ; nb_dom_cuts += length(ineqs) *2
        for inq in ineqs
            @constraint(model, sum(x[i] for i in inq) ≥ 1)
            @constraint(model, sum(x[i] for i in inq) ≤ length(inq)-1 )
        end
    end
    

    # Gurobi parameters 
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

        if QCR 
            set_optimizer_attribute(model, "CPX_PARAM_QPMAKEPSDIND", 0)
            set_optimizer_attribute(model, "CPX_PARAM_QTOLININD", 0)    # todo !
        end

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
        if grb_solver
            set_optimizer_attribute(model, "NodeLimit", 1)
        else
            set_optimizer_attribute(model, "CPX_PARAM_NODELIM", 0)
            MOI.set(model, MOI.NumberOfThreads(), 1) # todo 
        end
    end 

    optimize!(model)

    if grb_solver
        open(logname, "r") do io print(read(io, String)) end
    end

    solved_time = round(solve_time(model) , digits = 4)
    explored_nodes = node_count(model)

    println("solved_time = ", solved_time)
    println("explored_nodes = ", explored_nodes)


    opt = termination_status(model)== OPTIMAL

    obj = QCR ? round(-objective_bound(model), digits=2) : round(objective_bound(model), digits = 2)
    println( " obj = $obj \t nb_dom_cuts=$nb_dom_cuts" )

    # output 
    if root
        println(fout, "root_relax = $obj")
    else
        println(fout, "opt = $opt") 
        println(fout, "obj_val = $obj") 
        println(fout, "solved_time = ", solved_time)
        println(fout, "explored_nodes = ", explored_nodes)   

        cut ? println(fout, "nb_dom_cuts = $nb_dom_cuts") : nothing 
    end

    close(fout)

end
