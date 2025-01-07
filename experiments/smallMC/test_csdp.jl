
using JuMP, Gurobi, CPLEX, LinearAlgebra, CSDP


N = 5

c = [-9 , -7, 2, 23, 12]

Q = [0 -48 4 36 -24 ;
     0  0 -7 36 -84 ;
     0  0  0 40  4 ; 
     0  0  0  0 -88 ;
     0  0  0  0  0
]

a = [1, 1, 0, 1, 1]

b = 2



function csdp_QCR()
    

    model = Model(CSDP.Optimizer)
    JuMP.set_silent(model)


    @variable(model, 0<= x[1:N] )
    @variable(model, X[1:N, 1:N], Symmetric)

    @constraint(model, [1 x'; x X] in PSDCone())

    
    @objective(model, Min, tr(Q * X) + c'*x )

    @constraint(model, a'*x == b) 


    con_μ = @constraint(model, [i in 1:N], X[i,i] - x[i] == 0)

    con_α = @constraint(model, [i in 1:N], sum(a[j] * X[i,j] for j in 1:N) - b*x[i] == 0) 

    optimize!(model)

    if termination_status(model)== OPTIMAL
        sol = value.(x)
        obj = objective_value(model)

        println("obj = ", obj, " \n x = ", sol, "\n X = ", value.(X))

        μ = dual.(con_μ)

        α = dual.(con_α)

        println("μ = ", μ)

        println("α = ", α)

        return -α, -μ
    end

    return zeros(N), zeros(N)
end



function csdp_QCR2()
    

    model = Model(CSDP.Optimizer)
    JuMP.set_silent(model)


    @variable(model, 0<= x[1:N] )
    @variable(model, X[1:N, 1:N], Symmetric)

    @constraint(model, [1 x'; x X] in PSDCone())

    
    @objective(model, Min, tr(Q * X) + c'*x )

    @constraint(model, a'*x == b) 


    con_μ = @constraint(model, [i in 1:N], X[i,i] - x[i] == 0)

    con_β = @constraint(model, sum(a[i]*a[j]*X[i,j] for i in 1:N for j in 1:N) - 
                            2 * sum(b * a[j] * x[j] for j in 1:N) +
                            b^2  == 0 
            ) 

    optimize!(model)

    if termination_status(model)== OPTIMAL
        sol = value.(x)
        obj = objective_value(model)

        println("obj = ", obj, " \n x = ", sol, "\n X = ", value.(X))

        μ = dual.(con_μ)

        β = dual(con_β)

        println("μ = ", μ)

        println("β = ", β)

        return -β, -μ
    end

    return 0.0, zeros(N)
end




function solve(QCR)
        

    model = Model(CPLEX.Optimizer)

    @variable(model, 0 <= x[1:N] <= 1 )

    if QCR
        # α, μ = csdp_QCR()

        # @objective(model, Min, x'*Q*x + c'*x  + 
        #                         sum(μ[i] * (x[i]^2 - x[i]) for i in 1:N) +
        #                         sum(α[i] * x[i] for i in 1:N ) * ( a'*x -b )
        # )

        β, μ = csdp_QCR2()

        @objective(model, Min, x'*Q*x + c'*x + 
                                sum(μ[i] * (x[i]^2 - x[i]) for i in 1:N) +
                                β * (a'*x - b )^2
        )

    else
        @objective(model, Min, x'*Q*x + c'*x )
    end

    @constraint(model, a'*x == b) 

    #todo : Gurobi
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
    # set_attribute(model, "PSDCuts", 0)

    # set_attribute(model, "PreQLinearize", 0)

    # set_attribute(model, "NonConvex", 0)


    # todo : CPLEX 
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


    # set_optimizer_attribute(model, "CPX_PARAM_PREIND", 0)
    set_optimizer_attribute(model, "CPX_PARAM_AGGIND", 0)
    set_optimizer_attribute(model, "CPX_PARAM_RELAXPREIND", 0)
    set_optimizer_attribute(model, "CPX_PARAM_PREPASS", 0)
    set_optimizer_attribute(model, "CPX_PARAM_REPEATPRESOLVE", 0)
    set_optimizer_attribute(model, "CPX_PARAM_BNDSTRENIND", 0)
    set_optimizer_attribute(model, "CPX_PARAM_COEREDIND", 0)
    # set_optimizer_attribute(model, "CPX_PARAM_REDUCE", 0)
    set_optimizer_attribute(model, "CPXPARAM_Preprocessing_Symmetry", 0)




    MOI.set(model, MOI.NumberOfThreads(), 1) # todo 

    optimize!(model)


    if termination_status(model)== OPTIMAL
        sol = value.(x)
        obj = objective_value(model)

        println("obj = ", obj, " \n x = ", sol)

    end


end


# solve(false)

solve(true)

