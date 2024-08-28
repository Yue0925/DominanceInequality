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

    # todo : boucle de one swap ∀ i,j
    for i in 1:kp.N-1
        for j in i+1:kp.N
            u = 0 ; v = 0 

            println("boucle i $i , j $j")
            if kp.P[i] > kp.P[j]
                v = i ; u = j 
            elseif kp.P[i] == kp.P[j]
                continue
            else
                u = i ; v = j 
            end

            println("-----------------------------------------")
            println("\t swap $u by $v ")

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
                if pt[u] == 1 && pt[v] == 0
                    

                # # todo swap 
                # for u in 1:kp.N     # object u is packed 
                #     if pt[u] == 0 continue end 

                #     for v in 1:kp.N     # object v is free 
                #         if pt[v] == 1 continue end


                        # if residual capacity >= 0 && profit v > u
                        # then delete actual dominated pt
                        if kp.B - pt'*kp.W + kp.W[u] - kp.W[v] ≥ 0 # todo : (move before) && kp.P[v] - kp.P[u] > 0
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
            newfile = "./completeOneSwap/" * kp.name * "_u$(u)_v$(v).poi"
            f = open(newfile, "w")
            println(f, "DIM = ", kp.N) ; println(f)
            println(f, "CONV_SECTION")

            o = 0
            for pt in feasiblePts
                o += 1
                if o < 10 
                    print(f, "(  $o) ")
                elseif o < 100
                    print(f, "( $o) ")
                else
                    print(f, "($o) ")
                end

                for x in pt print(f, "$x ") end 
                println(f)

            end

            println(f)
            println(f, "END")
            close(f)



        end
    end


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


function verifyObjcut2(fname::String)
    kp = readInstance(fname)

    M = Model(CPLEX.Optimizer)
    @variable(M,0<= x[1:kp.N] <=1)
    @constraint(M, x'*kp.W <= kp.B)
    @objective(M, Max, x'*kp.P)

    optimize!(M)

    LP = JuMP.value.(x)

    println("LP => $LP \n")

    # 
    for u in 1:kp.N
        if LP[u] != 1.0 continue end 

        for v in 1:kp.N 
            if LP[v] == 1.0 || LP[v] == 0.0 continue end 

            # swap u,v 
            println("operation swap u=$u ans v=$v ... ")

            Pi = max(0.0, (1-LP[v])*kp.W[v] - kp.W[u])

            println("feasibility Pi = $Pi")

            if kp.P[v]*(1-LP[v]) - kp.P[u] > kp.P[v]*(LP[v] + Pi)
                println(" ------------- found f^obj cut (swap $u, $v ) violates LP opt !!!")
            end
            println("l'écart $(kp.P[v]*(1-LP[v]) - kp.P[u] - kp.P[v]*(LP[v] + Pi))")
        end
    end

end

# verifyObjcut2(ARGS[1])

dominanceFilterage(ARGS[1])