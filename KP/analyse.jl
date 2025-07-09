using JuMP, CPLEX, Combinatorics

# ----------------------
# ---- data 
# N = 7

# P = [7, 5, 37, 20, 70, 10, 39]

# W = [4, 3, 19, 10, 31, 6, 20]

# B = 50
N = 7

P = [7, 3, 4, 82, 81, 76, 72]

W = [4, 2, 4, 82, 82, 77, 75]

B = 85



# -----------------------
# ----- model


M = Model(CPLEX.Optimizer)
@variable(M, 0<= x[1:N] <=1)
@constraint(M, x'*W <= B)
@objective(M, Max, x'*P)

optimize!(M)

x_LP = JuMP.value.(x)


println("LP sol = " , x_LP)

# @constraint(M, x[7]+x[4]+x[5] <= 2)
# @constraint(M, x[7]+x[5] <= 1)

# @constraint(M, x[3]+x[4]+x[5] <= 2)

# ----------------------
# -- add cover 

all_subsets = powerset([i for i in 1:N])

for cover in all_subsets
    if length(cover) <=1
        continue
    end

    weight = sum(W[i] for i in cover)
    if weight > B
        println("set = ", cover)

        println("its a valid cover ")
        # if sum(sol[i] for i in cover) > length(cover)-1
        #     @info "violated cover "
        # end
        @constraint(M, sum(x[i] for i in cover) <= length(cover)-1)
    end
end

optimize!(M)

x_cover = JuMP.value.(x)
println("cover sol = " , x_cover)

@constraint(M, x[2] ≤ x[3]+x[4]+x[5])
optimize!(M)

x_dom = JuMP.value.(x)
println("dom sol = " , x_dom)




# ------------- sol 
# LP sol = [1.0, 1.0, 0.0, 0.9634146341463415, 0.0, 0.0, 0.0]
# cover sol = [0.978021978021978, 1.0, 0.04395604395604391, 0.02197802197802201, 0.02197802197802201, 0.978021978021978, 0.0]







# using XPORTA


# function transferIEQ(fname::String)

#     mc_poi = XPORTA.read_poi(fname)

#     mc_ieq = traf(mc_poi)

#     XPORTA.write_ieq(fname, mc_ieq)
# end


# transferIEQ(ARGS[1])