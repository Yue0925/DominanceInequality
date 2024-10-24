
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
        if x[i] == 0    # todo i in V_2
            #todo: variation fonction 
            Δ = 0
            # i line 
            for j in i:N
                Δ += W[i,j] * (1 - 2 * x[j] )  
            end
            # i column 
            for j in i:N
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




function allFilter(fname::String)
    obj = split( split(fname, "/")[end], "." )[1]
    include("instances/" * obj)

    for i in 1:N  
        dominanceFilter_insertionleft(fname, i)
    end
end


# allFilter("PolyMaxCUt/MaxCut_5_1.poi")


allFilter(ARGS[1])