include("../warmUp.jl")
include("../solveMaxCut.jl")


"""
format u v w_uv
"""
function readFormat1(fname)
    f = open(fname)

    line = readline(f)

    n = parse(Int64, split(line, " ")[1] ) ; l = parse(Int64, split(line, " ")[2] ) 
    W = zeros(n, n)

    for i in 1:l
        line = readline(f)
        v = split(line, " ")

        i = parse(Int64, v[1]) ; j = parse(Int64, v[2] ) 
        w = parse(Float64, v[3] ) 
        W[i,j] = w

        # println("W[$i, $j] = $w")
    end

    close(f)

    # for i in 1:n
    #     for j in 1:n
    #         if i==j continue end 
    #         if W[i,j] != 0.0 && W[j,i] != W[i, j]
    #             error("directed edges !! W[$i, $j] = $(W[i, j]) and W[$j, $i] = $(W[j, i])")
    #         end
    #     end
        
    # end
    return n, W
end

"""
w,w,w,w ...
w,w,w,w ...
"""
function readFormat2(fname)
    N = 0; W= []; col = 0
    f = open(fname)

    for line in readlines(f)
        N += 1

        if col == 0 
            col = length(split(line, ","))
        elseif col != length(split(line, ","))
            error("line $N, col = ", length(split(line, ",")))
        end

        push!(W, parse.(Float64, split(line, ",")) )
    end
    close(f)

    Mat = reduce(vcat,transpose.(W))

    return N, Mat
end

function run(fname)
    folder = "./res/"
    if !isdir(folder)
        mkdir(folder)
    end

    N, W = nothing, nothing
    println("reading $fname ... ")

    if split(fname, "/")[end-1] == "instances_neg"
        N, W = readFormat1(fname)
        println("N = ", N)

    elseif split(fname, "/")[end-1] == "instances_neqfloat"
        N, W = readFormat2(fname)
        println("N = ", N)

    elseif split(fname, "/")[end-1] == "instances_uni"
        N, W = readFormat2(fname)
        println("N = ", N)
        
    else
        error("Unkown input file $fname ...")
    end

    # -------------------------------
    # ---- Gurobi -------------------
    # -------------------------------
    warmUp(grb_solver=true, QCR=true)
    println("# -------------------------- \n\n")

    folder = "./res/Gurobi"
    if !isdir(folder)
        mkdir(folder)
    end

 
    folder = "./res/Gurobi/QP"
    if !isdir(folder)
        mkdir(folder)
    end
    logname = folder * "/" *split(fname, "/")[end]
    if isfile(logname)
        nothing
    else
        println("loging $logname ... ")
        one_solve(N, W, logname, cut=false, grb_solver=true, QCR=false , root=true )
        one_solve(N, W, logname, cut=false, grb_solver=true, QCR=false , root=false )
    end


end


run(ARGS[1])

