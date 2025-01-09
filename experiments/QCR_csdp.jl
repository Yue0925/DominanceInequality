
using LinearAlgebra, JuMP, CSDP

include("dominanceInequalities.jl")

"""
Return the convexification coefficients Q and c. 
"""
function csdp_QCR(W, N; cut=false)
    println("QCR ...")

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
        ineqs = all_insertion_left_ineq(N, W) ; nb_dom_cuts += length(ineqs) *2
        for inq in ineqs
            @constraint(model, sum(x[i] for i in inq) ≥ 1)

            @constraint(model, sum(x[i] for i in inq) ≤ length(inq)-1 )
        end
    end


    @objective(model, Min, tr(-Q * X) - c'*x )

    con5 = @constraint(model, [i in 1:N], X[i,i] - x[i] == 0)


    optimize!(model)

    QCR_time = round(solve_time(model) , digits = 4)
    println("QCR_time = ", QCR_time)
    QCR_obj = 0.0

    if termination_status(model)== OPTIMAL
        QCR_obj = objective_value(model)
        println("QCR_obj = ", -QCR_obj)
        ϕ5 = dual.(con5)

        S = -Q 
        for i in 1:N
            S[i,i] -= ϕ5[i]
        end

        # println("S is PSD ? ", minimum(eigvals(S))>=0.0 ) 


        if minimum(eigvals(S))>=0.0 
            return -ϕ5, QCR_time
        else 
            error("QCR method errors ! ")
        end
    else
        error("QCR failured ! ")
    end

    return zeros(N), QCR_time
end
