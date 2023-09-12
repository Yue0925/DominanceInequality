mutable struct Knapsack 
    N :: Int64
    P :: Vector{Int64}
    W :: Vector{Int64}
    B :: Int64
    name :: String
end



function Knapsack(N :: Int64, P::Vector{Int64}, W::Vector{Int64}, B::Int64, name::String)
    return Knapsack(N, P, W, B, name )
end



function readInstance(fname::String)::Knapsack
    include(fname)
    inst = Knapsack(N, P, W, B, split(fname, "/")[end]  )
    return inst
end


function writeIeqFile(kp::Knapsack)
    fname = "./PolyKP/" * kp.name * ".ieq"

    fout = open(fname, "w")

    println(fout, "DIM = ", kp.N) ; println(fout)

    println(fout, "LOWER_BOUNDS")

    for i in 1:kp.N
        print(fout, "0 ")
    end
    println(fout)

    println(fout, "UPPER_BOUNDS")
    for i in 1:kp.N
        print(fout, "1 ")
    end
    println(fout)

    println(fout)
    println(fout, "INEQUALITIES_SECTION")

    print(fout, "$(kp.W[1])x1 ")
    for i in 2:kp.N
        print(fout, "+ $(kp.W[i])x$i ")
    end
    print(fout, "<= ")

    println(fout, kp.B)

    println(fout)

    println(fout, "END")


    close(fout)
    
end


# writeIeqFile(readInstance(ARGS[1]))