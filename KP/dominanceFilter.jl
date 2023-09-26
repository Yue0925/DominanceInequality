include("parser.jl")
using JuMP, CPLEX

function dominanceFilterage(fname::String)
    kp = readInstance(fname)

    # # -------------------------------------------------
    # # write all pair swap inequality 
    # # -------------------------------------------------
    # inequalityFile = "./PolyKP/" * kp.name * ".txt"
    # f = open(inequalityFile, "w") ; println(f, "# all swap dominance inequalities \n")

    # for u in 1:kp.N 
    #     for v in 1:kp.N
    #         if u==v continue end 
    #         println(f, "-$(kp.P[u])x$u + $(kp.P[v])(1 - x$v) <= $(kp.P[v])(1 - x$u + x$v +π$u$v)")
    #     end
    # end

    # close(f)

    # -------------------------------------------------
    # etape 1 : read all integer point 
    # -------------------------------------------------
    feasiblePts = Vector{Vector{Int64}}()
    filename = "./PolyKP/" * kp.name * ".poi"


    f = open(filename)
    lines = readlines(f)
    close(f)

    for line in lines
        if length(line) == 0 || line[1] != '(' continue end 
        l = parse.(Int64, split(split(line, ")")[end], " ")[2:end-1])

        @assert length(l) == kp.N

        push!(feasiblePts, l)
    end

    # -------------------------------------------------
    # etape 2 : for each point, find neighbouring point + compare + filter dominated one 
    # -------------------------------------------------
    dominated = Set{Int64}() ; idx = 0
    for pt in feasiblePts
        idx += 1

        # todo one swap 
        # ratio = kp.P./kp.W
        # dic = Dict(i => ratio[i] for i in 1:kp.N)
        
        u = 1; v = kp.N 
        if pt[u] == 1 && pt[v] == 0
            

        # # todo swap 
        # for u in 1:kp.N     # object u is packed 
        #     if pt[u] == 0 continue end 

        #     for v in 1:kp.N     # object v is free 
        #         if pt[v] == 1 continue end


                # if residual capacity >= 0 && profit v > u
                # then delete actual dominated pt
                if kp.B - pt'*kp.W + kp.W[u] - kp.W[v] ≥ 0 && kp.P[v] - kp.P[u] > 0
                    push!(dominated, idx)
                end
        #     end
        # end
        end


        # #todo insert
        # for u in 1:kp.N     # object u is free 
        #     if pt[u] == 1 continue end

        #     # if pushing object u is feasible (residual capa ≥ 0) and is dominated 
        #     if kp.B - pt'*kp.W - kp.W[u] ≥ 0 && kp.P[u] > 0
        #         push!(dominated, idx)
        #     end
        # end
    end


    println("total feasible points => $(length(feasiblePts))")

    deleteat!(feasiblePts, sort(collect(dominated)))

    println("where dominated ones => $(length(dominated)) ")


    # -------------------------------------------------
    # etape 3 : write all filtered point into .poi file (ready compute convex hull with traf)
    # -------------------------------------------------
    # todo : 
    newfile = "./oneSwapDominance/" * kp.name * ".poi"
    f = open(newfile, "w")
    println(f, "DIM = ", kp.N) ; println(f)
    println(f, "CONV_SECTION")

    i = 0
    for pt in feasiblePts
        i += 1
        if i < 10 
            print(f, "(  $i) ")
        elseif i < 100
            print(f, "( $i) ")
        else
            print(f, "($i) ")
        end

        for x in pt print(f, "$x ") end 
        println(f)

    end

    println(f)
    println(f, "END")
    close(f)



end



function verifyObjcut(fname::String)
    kp = readInstance(fname)

    ratio = Dict{Int64, Float64}(i => kp.P[i]/kp.W[i] for i in 1:kp.N)

    sorted_ratio = sort(collect(ratio), by = x->x[2], rev=true)

    cover = Vector{Int64}()

    x_theory = zeros((kp.N)) ; CR = kp.B
    for (i, r) in sorted_ratio
        if CR - kp.W[i] <= 0 
            x_theory[i] = CR/ kp.W[i] ; push!(cover, i)
            break 
        end 
        x_theory[i] = 1.0 ; CR -= kp.W[i]
        push!(cover, i)
    end

    println("LP => x_theory=$x_theory")
    println("Cover at LP => $cover ")

    M = Model(CPLEX.Optimizer)
    @variable(M,0<= x[1:kp.N] <=1)
    @constraint(M, x'*kp.W <= kp.B)
    @constraint(M, sum(x[i] for i in cover) <= length(cover)-1)
    @objective(M, Max, x'*kp.P)

    optimize!(M)

    LP_cover = JuMP.value.(x)

    println("LP cover => $LP_cover \n")

end

verifyObjcut(ARGS[1])

# dominanceFilterage(ARGS[1])