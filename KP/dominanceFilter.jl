include("parser.jl")

function dominanceFilterage(fname::String)
    kp = readInstance(fname)

    # etape 1 : read all integer point 
    feasiblePts = Vector{Vector{Int64}}()
    filename = "./ieqOutput/" * kp.name * ".poi"

    f = open(filename)
    lines = readlines(f)
    close(f)

    for line in lines
        if length(line) == 0 || line[1] != '(' continue end 
        l = parse.(Int64, split(split(line, ")")[end], " ")[2:end-1])

        @assert length(l) == kp.N

        push!(feasiblePts, l)
    end


    # etape 2 : for each point, find neighbouring point + compare + filter dominated one 
    dominated = Set{Int64}() ; idx = 0
    for pt in feasiblePts
        idx += 1
        for u in 1:kp.N     # object u is packed 
            if pt[u] == 0 continue end 

            for v in 1:kp.N     # object v is free 
                if pt[v] == 1 continue end

                # if residual capacity >= 0 && profit v > u
                # then delete actual dominated pt
                if kp.B - pt'*kp.W + kp.W[u] - kp.W[v] ≥ 0 && kp.P[v] - kp.P[u] > 0
                    push!(dominated, idx)
                end
            end
        end
    end


    println("total feasible points => $(length(feasiblePts))")

    deleteat!(feasiblePts, sort(collect(dominated)))

    println("where dominated ones => $(length(dominated)) ")


    # etape 3 : write all filtered point into .poi file (ready compute convex hull with traf)

    newfile = "./dominanceFilter/" * kp.name * ".poi"
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

dominanceFilterage(ARGS[1])