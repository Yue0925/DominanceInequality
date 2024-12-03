
function feasibleSet(fname::String)
    f = open(fname)
    lines = readlines(f)
    close(f)

    feasibleSols = Vector{Vector{Int64}}()

    for line in lines
        if length(line) == 0 || line[1] != '(' continue end 
        l = parse.(Int64, split(split(line, ")")[end], " ")[2:end-1])
        push!(feasibleSols, l)

    end
    
    # println("length feasible set = ", length(feasibleSols))

    return feasibleSols
end



"""
Operation : insertion u∈V_2 to V_1

u fixed object 1
"""

function dominanceFilter_insertionleft(fname::String, i::Int64)
    Χ = feasibleSet(fname)
    obj = split( split(fname, "/")[end], "." )[1]
    include("instances/" * obj)

    println("\n ------------ $(obj) with $(i) -------------- ")
    println("total ", length(Χ), " feasible solutions ")
    
    idx_dominated = [] ; idx = 0

    # for x ∈ Χ
    for x in Χ
        idx += 1
        Δ = 0

        if x[i] == 0    # todo i in V_2

            for j in 1:N
                Δ += W[i,j] * (1 - 2 * x[j] )  
                
                Δ += W[j, i] * (1 - 2 * x[j] )
            end

            # println("Δ = ", Δ)
            if Δ > 0 
                push!(idx_dominated, idx )
            end
        end
    end

    println(length(idx_dominated), " dominated solutions (insertion left i.e. u from V_2 to V_1)")

    deleteat!(Χ, idx_dominated)

    println("|Χ_dom| = ", length(Χ))


    # writing dominant points 
    folder = "./insertionleft/"
    if !isdir(folder)
        mkdir(folder)
    end
    newfile = folder * obj * "_u$(i).poi"

    f = open(newfile, "w")
    println(f, "DIM = ", N) ; println(f)
    println(f, "CONV_SECTION")

    o = 0
    for pt in Χ
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


function dominanceFilter_insertionright(fname::String, i::Int64)
    Χ = feasibleSet(fname)
    obj = split( split(fname, "/")[end], "." )[1]
    include("instances/" * obj)

    println("\n ------------ $(obj) with $(i) -------------- ")
    println("total ", length(Χ), " feasible solutions ")
    
    idx_dominated = [] ; idx = 0

    # for x ∈ Χ
    for x in Χ
        idx += 1
        Δ = 0

        if x[i] == 1   # todo i in V_1

            for j in 1:N
                Δ += W[i,j] * (2 * x[j] -1 )  
                
                Δ += W[j, i] * (2 * x[j] -1)
            end

            # println("Δ = ", Δ)
            if Δ > 0 
                push!(idx_dominated, idx )
            end
        end
    end

    println(length(idx_dominated), " dominated solutions (insertion right i.e. u from V_1 to V_2)")

    deleteat!(Χ, idx_dominated)

    println("|Χ_dom| = ", length(Χ))


    # writing dominant points 
    folder = "./insertionright/"
    if !isdir(folder)
        mkdir(folder)
    end
    newfile = folder * obj * "_u$(i).poi"

    f = open(newfile, "w")
    println(f, "DIM = ", N) ; println(f)
    println(f, "CONV_SECTION")

    o = 0
    for pt in Χ
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



function dominanceFilter_swap(fname::String, u::Int64, v::Int64)
    Χ = feasibleSet(fname)
    obj = split( split(fname, "/")[end], "." )[1]
    include("instances/" * obj)

    println("\n ------------ $(obj) swap $(u) and $(v) -------------- ")
    println("total ", length(Χ), " feasible solutions ")
    
    idx_dominated = [] ; idx = 0

    # for x ∈ Χ
    for x in Χ
        idx += 1
        Δ = 0

        if x[u] == 1 && x[v]==0  # todo u in V_1 and v in V_2

            for i in 1:N
                if i==u || i==v continue end 

                Δ += W[u,i] * (2 * x[i] -1 )  
                
                Δ += W[i,u] * (2 * x[i] -1)

                Δ += W[i,v] * (1 - 2 * x[i])
                Δ += W[v,i] * (1 - 2 * x[i])
            end

            # Δ += 2 * (W[u,v] + W[v,u])
            # println("Δ = ", Δ)
            if Δ > 0 
                push!(idx_dominated, idx )
            end
        end
    end

    println(length(idx_dominated), " dominated solutions (swap u,v)")

    deleteat!(Χ, idx_dominated)

    println("|Χ_dom| = ", length(Χ))


    # writing dominant points 
    folder = "./swap/"
    if !isdir(folder)
        mkdir(folder)
    end
    newfile = folder * obj * "_u$(u)_v$(v).poi"

    f = open(newfile, "w")
    println(f, "DIM = ", N) ; println(f)
    println(f, "CONV_SECTION")

    o = 0
    for pt in Χ
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




function allFilter(fname::String)
    obj = split( split(fname, "/")[end], "." )[1]
    include("instances/" * obj)

    # for i in 1:N  
    #     # todo : 
    #     dominanceFilter_insertionleft(fname, i)

    #     # dominanceFilter_insertionright(fname, i)
    # end

    for u in 1:N-1
        for v in u+1:N
            dominanceFilter_swap(fname, u, v)
            dominanceFilter_swap(fname, v, u)
        end
    end
end


using XPORTA


function transferIEQ(fname::String)

    mc_poi = XPORTA.read_poi(fname)

    mc_ieq = traf(mc_poi)

    XPORTA.write_ieq(fname, mc_ieq)
end




function dominanceFilter_ALLinsertionleft(fname::String)
    Χ = feasibleSet(fname)
    obj = split( split(fname, "/")[end], "." )[1]
    include("instances/" * obj)


    println("total ", length(Χ), " feasible solutions ")
    
    idx_dominated = Set() ; idx = 0

    # for x ∈ Χ
    for x in Χ
        idx += 1

        for i in 1:N
            Δ = 0

            if x[i] == 0    # todo i in V_2

                for j in 1:N
                    Δ += W[i,j] * (1 - 2 * x[j] )  
                    
                    Δ += W[j, i] * (1 - 2 * x[j] )
                end

                # println("Δ = ", Δ)
                if Δ > 0 
                    push!(idx_dominated, idx ) ; break 
                end
            end
        end

    end

    idx_dominated = collect(idx_dominated)
    sort!(idx_dominated)

    println(length(idx_dominated), " dominated solutions (ALL insertion left i.e. u from V_2 to V_1)")

    deleteat!(Χ, idx_dominated)

    println("|Χ_dom| = ", length(Χ))


    # writing dominant points 
    folder = "./ALLinsertionleft/"
    if !isdir(folder)
        mkdir(folder)
    end
    newfile = folder * obj * ".poi"

    f = open(newfile, "w")
    println(f, "DIM = ", N) ; println(f)
    println(f, "CONV_SECTION")

    o = 0
    for pt in Χ
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


function variation_obj(x, u, v)
    Δ =0
    if x[u] == 1 && x[v]==0  # todo u in V_1 and v in V_2

        for i in 1:N
            if i==u || i==v continue end 

            Δ += W[u,i] * (2 * x[i] -1 )  
            
            Δ += W[i,u] * (2 * x[i] -1)

            Δ += W[i,v] * (1 - 2 * x[i])
            Δ += W[v,i] * (1 - 2 * x[i])
        end

    end
    return Δ
end

function dominanceFilter_ALLinsertionright(fname::String)
    Χ = feasibleSet(fname)
    obj = split( split(fname, "/")[end], "." )[1]
    include("instances/" * obj)


    println("total ", length(Χ), " feasible solutions ")
    
    idx_dominated = Set() ; idx = 0

    # for x ∈ Χ
    for x in Χ
        idx += 1

        for i in 1:N
            Δ = 0

            if x[i] == 1   # todo i in V_1

                for j in 1:N
                    Δ += W[i,j] * (2 * x[j] -1 )  
                    
                    Δ += W[j, i] * (2 * x[j] -1)
                end
    
                # println("Δ = ", Δ)
                if Δ > 0 
                    push!(idx_dominated, idx ) ; break
                end
            end

        end

    end

    idx_dominated = collect(idx_dominated)
    sort!(idx_dominated)

    println(length(idx_dominated), " dominated solutions (ALL insertion right i.e. u from V_1 to V_2)")

    deleteat!(Χ, idx_dominated)

    println("|Χ_dom| = ", length(Χ))


    # writing dominant points 
    folder = "./ALLinsertionright/"
    if !isdir(folder)
        mkdir(folder)
    end
    newfile = folder * obj * ".poi"

    f = open(newfile, "w")
    println(f, "DIM = ", N) ; println(f)
    println(f, "CONV_SECTION")

    o = 0
    for pt in Χ
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




function dominanceFilter_ALLswap(fname::String)
    Χ = feasibleSet(fname)
    obj = split( split(fname, "/")[end], "." )[1]
    include("instances/" * obj)


    println("total ", length(Χ), " feasible solutions ")
    
    idx_dominated = Set() ; idx = 0

    # for x ∈ Χ
    for x in Χ
        idx += 1

        for u in 1:N-1
            for v in u+1:N

                # todo : 1 swap u,v 
                Δ = variation_obj(x, u, v)
                if Δ > 0 
                    push!(idx_dominated, idx ) ; break
                end

                # todo : swap v,u
                Δ = variation_obj(x, v, u)
                if Δ > 0 
                    push!(idx_dominated, idx ) ; break
                end

            end

        end 

    end

    idx_dominated = collect(idx_dominated)
    sort!(idx_dominated)

    println(length(idx_dominated), " dominated solutions (ALL swap )")

    deleteat!(Χ, idx_dominated)

    println("|Χ_dom| = ", length(Χ))


    # writing dominant points 
    folder = "./ALLswap/"
    if !isdir(folder)
        mkdir(folder)
    end
    newfile = folder * obj * ".poi"

    f = open(newfile, "w")
    println(f, "DIM = ", N) ; println(f)
    println(f, "CONV_SECTION")

    o = 0
    for pt in Χ
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



function leftright_polytope(fname)
    inst = split(fname, "/")[end]

    left_feas_pts = feasibleSet("./ALLinsertionleft/" * inst)
    right_feas_pts = feasibleSet("./ALLinsertionright/" * inst)

    intersection_pts = []

    for pt in left_feas_pts
        if pt in right_feas_pts
            push!(intersection_pts, pt )
        end
    end

    n = length(intersection_pts[1])

    # writing dominant points 
    folder = "./leftright/"
    if !isdir(folder)
        mkdir(folder)
    end
    newfile = folder * inst 

    f = open(newfile, "w")
    println(f, "DIM = ", n) ; println(f)
    println(f, "CONV_SECTION")

    o = 0
    for pt in intersection_pts
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



# leftright_polytope("PolyMaxCut/MaxCut_4_1.poi")

# leftright_polytope(ARGS[1])
# allFilter("PolyMaxCut/MaxCut_4_1.poi")


# allFilter(ARGS[1])

transferIEQ(ARGS[1])


# dominanceFilter_ALLinsertionleft(ARGS[1])

# dominanceFilter_ALLinsertionright(ARGS[1])

# dominanceFilter_ALLswap(ARGS[1])