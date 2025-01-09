"""
    small MaxCut instance program. 
"""

using JuMP, Gurobi, CPLEX

include("QCR_csdp.jl")

N = 10
W = [0 21 21 12 48 13 12 18 48 7; 0 0 34 42 46 33 32 29 30 45; 0 0 0 45 12 12 25 31 5 35; 0 0 0 0 28 29 33 47 32 15; 0 0 0 0 0 22 36 9 8 9; 0 0 0 0 0 0 37 37 40 42; 0 0 0 0 0 0 0 21 40 48; 0 0 0 0 0 0 0 0 29 6; 0 0 0 0 0 0 0 0 0 35; 0 0 0 0 0 0 0 0 0 0]


function warmUp( ; grb_solver=true, QCR=false )
    println("warming up ...")

    if grb_solver 
        model = Model(Gurobi.Optimizer) 
    else
        model = Model(CPLEX.Optimizer) 
    end

    JuMP.set_silent(model)
 
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

        λ, _ = csdp_QCR(W, N)
        f = x'*(-Q)*x -c'*x + sum((λ[i]+0.00001) * (x[i]^2 - x[i] ) for i in 1:N)
        @objective(model, Min, f)
    else
        f = sum( W[i,j] * (x[i]*(1-x[j]) + x[j]*(1-x[i]) ) for i in 1:N for j in 1:N) 
        @objective(model, Max, f)
    end

    # Gurobi parameters 
    if grb_solver
        # set_attribute(model, "Presolve", 0)
        # set_attribute(model, "AggFill", -1)
        # set_attribute(model, "Aggregate", 0)
        # set_attribute(model, "Heuristics", 0)
        # set_attribute(model, "LPWarmStart", 0)
        # set_attribute(model, "NLPHeur", 0)
        # set_attribute(model, "NoRelHeurTime", 0)
        # set_attribute(model, "PreCrush", 0)
        # set_attribute(model, "PreDepRow", 0)
        # set_attribute(model, "PreDual", 0)
        # set_attribute(model, "PrePasses", -1)
        # set_attribute(model, "RINS", 0)
        # set_attribute(model, "Symmetry", 0)
        # # set_attribute(model, "PSDCuts", 0)

        set_attribute(model, "PreQLinearize", 0)

        if QCR
            set_attribute(model, "NonConvex", 0)
        end
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


    optimize!(model)

    solved_time = solve_time(model) 
    explored_nodes = node_count(model)

    obj = 0.0
    opt = termination_status(model)== OPTIMAL

    obj = objective_bound(model)
end

