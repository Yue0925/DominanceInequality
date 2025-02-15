


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



function read_obj_val(fname, fout)
    obj_val = 0.0 ; exist = false 

    f = open(fname, "r")
    for lines in readlines(f)
        line = split(lines, " ")

        if line[1] == "obj_val"
            exist = true
            print(fout, line[end], " & ")
            break
        end
    end

    close(f)

    if !exist print(fout, " & ") end 

end


function read_opt(fname, fout)
    opt = nothing ; exist = false 

    f = open(fname, "r")
    for lines in readlines(f)
        line = split(lines, " ")

        if line[1] == "opt"
            exist = true
            print(fout, line[end], " & ")
            break
        end
    end

    close(f)

    if !exist print(fout, " & ") end 

end



function read_solved_time(fname, fout)
    solved_time = nothing ; exist = false 

    f = open(fname, "r")
    for lines in readlines(f)
        line = split(lines, " ")

        if line[1] == "solved_time"
            exist = true
            print(fout, line[end], " & ")
            break
        end
    end

    close(f)

    if !exist print(fout, " & ") end 

end



function read_explored_nodes(fname, fout)
    explored_nodes = nothing ; exist = false 

    f = open(fname, "r")
    for lines in readlines(f)
        line = split(lines, " ")

        if line[1] == "explored_nodes"
            exist = true
            print(fout, line[end], " & ")
            break
        end
    end

    close(f)

    if !exist print(fout, " & ") end 

end



function read_root_relax(fname, fout)
    root_relax = nothing ; exist = false 

    f = open(fname, "r")
    for lines in readlines(f)
        line = split(lines, " ")

        if line[1] == "root_relax"
            exist = true
            print(fout, line[end], " & ")
            break
        end
    end

    close(f)

    if !exist print(fout, " & ") end 

end



function read_nb_dom_cuts(fname, fout)
    nb_dom_cuts = nothing ; exist = false 

    f = open(fname, "r")
    for lines in readlines(f)
        line = split(lines, " ")

        if line[1] == "nb_dom_cuts"
            exist = true
            print(fout, line[end], " & ")
            break
        end
    end

    close(f)

    if !exist print(fout, " & ") end 

end



function read_QCR_time(fname, fout)
    QCR_time = nothing ; exist = false 

    f = open(fname, "r")
    for lines in readlines(f)
        line = split(lines, " ")

        if line[1] == "QCR_time"
            exist = true
            print(fout, line[end], " & ")
            break
        end
    end

    close(f)

    if !exist print(fout, " & ") end 

end

function writeLine(fname, fout)
    read_obj_val(fname, fout)
    read_opt(fname, fout)
    read_solved_time(fname, fout)
    read_explored_nodes(fname, fout)
    read_root_relax(fname, fout)

end



function run(fname)
  
    N, W = readFormat1(fname)


    fileName = "Gurobiresult.txt"
    fout = open(fileName, "a")


    inst = split(fname, "/")[end] 
    logFolder = "./res/Gurobi/QP"
    if isfile(logFolder * "/" * inst)

        print(fout, inst , " & ", N , " & ")
        writeLine(logFolder * "/" * inst, fout)


        logFolder = "./res/Gurobi/QP_Dom"
        if isfile(logFolder * "/" * inst)
            writeLine(logFolder * "/" * inst, fout)
            read_nb_dom_cuts(logFolder * "/" * inst, fout)

        else
            print(fout, " & & & & & & ")
        end


        logFolder = "./res/Gurobi/QCR_QP"
        if isfile(logFolder * "/" * inst)
            read_QCR_time(logFolder * "/" * inst, fout)
            writeLine(logFolder * "/" * inst, fout)

        else
            print(fout, " & & & & & & ")
        end


        logFolder = "./res/Gurobi/QCR_QP_Dom"
        if isfile(logFolder * "/" * inst)
            read_QCR_time(logFolder * "/" * inst, fout)
            writeLine(logFolder * "/" * inst, fout)
            read_nb_dom_cuts(logFolder * "/" * inst, fout)

        else
            print(fout, " & & & & & & & ")
        end

        println(fout, "\\\\")

    end

    close(fout)





    fileName = "Cplexresult.txt"
    fout = open(fileName, "a")


    inst = split(fname, "/")[end] 
    logFolder = "./res/Cplex/QP"
    if isfile(logFolder * "/" * inst)

        print(fout, inst , " & ", N , " & ")
        writeLine(logFolder * "/" * inst, fout)


        logFolder = "./res/Cplex/QP_Dom"
        if isfile(logFolder * "/" * inst)
            writeLine(logFolder * "/" * inst, fout)
            read_nb_dom_cuts(logFolder * "/" * inst, fout)

        else
            print(fout, " & & & & & & ")
        end


        logFolder = "./res/Cplex/QCR_QP"
        if isfile(logFolder * "/" * inst)
            read_QCR_time(logFolder * "/" * inst, fout)
            writeLine(logFolder * "/" * inst, fout)

        else
            print(fout, " & & & & & & ")
        end


        logFolder = "./res/Cplex/QCR_QP_Dom"
        if isfile(logFolder * "/" * inst)
            read_QCR_time(logFolder * "/" * inst, fout)
            writeLine(logFolder * "/" * inst, fout)
            read_nb_dom_cuts(logFolder * "/" * inst, fout)

        else
            print(fout, " & & & & & & & ")
        end

        println(fout, "\\\\")

    end

    close(fout)


end

run(ARGS[1])
