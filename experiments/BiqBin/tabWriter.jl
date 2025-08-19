


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


function read_obj_val(fname, fout)
    obj_val = 0.0 ; exist = false 

    f = open(fname, "r")
    for lines in readlines(f)
        line = split(lines, " ")

        if line[1] == "obj_val"
            exist = true
            obj_val = parse(Float64, line[end])
            print(fout, abs(obj_val), " & ")
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
            t = round(parse(Float64, line[end]), digits = 2)
            t > 1800 ? print(fout, "TO & ") :  print(fout, t, " & ")
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
            root_relax = round(parse(Float64, line[end]), digits =2)
            print(fout, abs(root_relax), " & ")
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


function read_CP(fname, fout)
    nb_cuts = 0 ; exist = false 

    f = open(fname, "r")
    for lines in readlines(f)
        line = exist ? split(lines, " ") : split(lines, ":")

        if line[1] == "Cutting planes"
            exist = true
            continue
        end

        if exist
            if length(line) >1
                nb_cuts += parse(Int, line[end])
            else
                print(fout, nb_cuts, " & ")
                # println(nb_cuts)
                break
            end
        end
    end

    close(f)

    if !exist print(fout, "0 & ") end 

end

function read_QCR_time(fname, fout)
    QCR_time = nothing ; exist = false 

    f = open(fname, "r")
    for lines in readlines(f)
        line = split(lines, " ")

        if line[1] == "QCR_time"
            exist = true
            t = round(parse(Float64, line[end]), digits = 2)
            t > 1800 ? print(fout, "TO & ") :  print(fout, t, " & ")
            # print(fout, line[end], " & ")
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
    N, W = nothing, nothing

    if split(fname, "/")[end-1] == "instances_neg"
        N, W = readFormat1(fname)

    elseif split(fname, "/")[end-1] == "instances_neqfloat"
        N, W = readFormat2(fname)

    elseif split(fname, "/")[end-1] == "instances_uni"
        N, W = readFormat2(fname)
        
    else
        error("Unkown input file $fname ...")
    end

    fileName = "Gurobiresult.txt"
    fout = open(fileName, "a")

    density = 0
    for i in 1:N 
        for j in 1:N
            if W[i,j] != 0.0 density += 1 end 
        end 
    end


    inst = split(fname, "/")[end] 
    # -----------------------------
    # - inst & N & density 
    print(fout, inst , " & ", N , " & ", round(100 * density/N^2, digits = 1), " & ")


    # # -----------------------------
    # # ----      QP
    # logFolder = "./res/Gurobi/QP"
    # if isfile(logFolder * "/" * inst)
    #     writeLine(logFolder * "/" * inst, fout)
    # else
    #     print(fout, " & & & & & ")
    # end

    # # -----------------------------
    # # ---    QP + Dom cuts 
    # logFolder = "./res/Gurobi/QP_Dom"
    # if isfile(logFolder * "/" * inst)
    #     writeLine(logFolder * "/" * inst, fout)
    #     read_nb_dom_cuts(logFolder * "/" * inst, fout)

    # else
    #     print(fout, " & & & & & & ")
    # end

    # -----------------------------
    # ---      QCR + QP 
    logFolder = "./res/Gurobi/QCR_QP"
    if isfile(logFolder * "/" * inst)
        read_QCR_time(logFolder * "/" * inst, fout)
        writeLine(logFolder * "/" * inst, fout)

    else
        print(fout, " & & & & & & ")
    end

    # # -----------------------------
    # # ---    Dom + QCR + QP 
    # logFolder = "./res/Gurobi/Dom_QCR_QP"
    # if isfile(logFolder * "/" * inst)
    #     read_nb_dom_cuts(logFolder * "/" * inst, fout)
    #     read_QCR_time(logFolder * "/" * inst, fout)
    #     writeLine(logFolder * "/" * inst, fout)

    # else
    #     print(fout, "& & & & & & & ")
    # end


    # -----------------------------
    # ---    QCR + QP + Dom 
    logFolder = "./res/Gurobi/QCR_QP_Dom"
    if isfile(logFolder * "/" * inst)
        read_QCR_time(logFolder * "/" * inst, fout)
        writeLine(logFolder * "/" * inst, fout)
        read_nb_dom_cuts(logFolder * "/" * inst, fout)

    else
        print(fout, " & & & & & & & ")
    end


    # # -----------------------------
    # # ---    QCR2 + QP 
    # logFolder = "./res/Gurobi/QCR2_QP"
    # if isfile(logFolder * "/" * inst)
    #     read_QCR_time(logFolder * "/" * inst, fout)
    #     writeLine(logFolder * "/" * inst, fout)
    #     read_CP(logFolder * "/" * inst, fout)

    # else
    #     print(fout, "& & & & & & & ")
    # end

    # # -----------------------------
    # # ---    QCR2 + QP + Dom 
    # logFolder = "./res/Gurobi/QCR2_QP_Dom"
    # if isfile(logFolder * "/" * inst)
    #     read_QCR_time(logFolder * "/" * inst, fout)
    #     writeLine(logFolder * "/" * inst, fout)
    #     read_nb_dom_cuts(logFolder * "/" * inst, fout)
    #     read_CP(logFolder * "/" * inst, fout)

    # else
    #     print(fout, " & & & & & & & & ")
    # end

    # # -----------------------------
    # # ---    Dom + QCR2 + QP 
    # logFolder = "./res/Gurobi/Dom_QCR2_QP"
    # if isfile(logFolder * "/" * inst)
    #     read_nb_dom_cuts(logFolder * "/" * inst, fout)
    #     read_QCR_time(logFolder * "/" * inst, fout)
    #     writeLine(logFolder * "/" * inst, fout)
    #     read_CP(logFolder * "/" * inst, fout)

    # else
    #     print(fout, "& & & & & & & & ")
    # end

    # # -----------------------------
    # # ---    Dom + QCR2 + QP +Dom
    # logFolder = "./res/Gurobi/Dom_QCR2_QP_Dom"
    # if isfile(logFolder * "/" * inst)
    #     read_nb_dom_cuts(logFolder * "/" * inst, fout)
    #     read_QCR_time(logFolder * "/" * inst, fout)
    #     writeLine(logFolder * "/" * inst, fout)
    #     read_nb_dom_cuts(logFolder * "/" * inst, fout)
    #     read_CP(logFolder * "/" * inst, fout)

    # else
    #     print(fout, "& & & & & & & & & ")
    # end
  

    println(fout, "\\\\")


    close(fout)




    # fileName = "Cplexresult.txt"
    # fout = open(fileName, "a")


    # inst = split(fname, "/")[end] 

    # # -----------------------------
    # # - inst & N & density 
    # print(fout, inst , " & ", N , " & ", round(100 * density/N^2, digits = 4), " & ")


    # # -----------------------------
    # # ----      QP
    # logFolder = "./res/Cplex/QP"
    # if isfile(logFolder * "/" * inst)
    #     writeLine(logFolder * "/" * inst, fout)
    # else
    #     print(fout, " & & & & & ")
    # end

    # # -----------------------------
    # # ---     QP + Dom cuts
    # logFolder = "./res/Cplex/QP_Dom"
    # if isfile(logFolder * "/" * inst)
    #     writeLine(logFolder * "/" * inst, fout)
    #     read_nb_dom_cuts(logFolder * "/" * inst, fout)

    # else
    #     print(fout, " & & & & & & ")
    # end

    # # -----------------------------
    # # ---     QCR + QP
    # logFolder = "./res/Cplex/QCR_QP"
    # if isfile(logFolder * "/" * inst)
    #     read_QCR_time(logFolder * "/" * inst, fout)
    #     writeLine(logFolder * "/" * inst, fout)

    # else
    #     print(fout, " & & & & & & ")
    # end

    # # -----------------------------
    # # ---    Dom + QCR + QP 
    # logFolder = "./res/Cplex/Dom_QCR_QP"
    # if isfile(logFolder * "/" * inst)
    #     read_nb_dom_cuts(logFolder * "/" * inst, fout)
    #     read_QCR_time(logFolder * "/" * inst, fout)
    #     writeLine(logFolder * "/" * inst, fout)

    # else
    #     print(fout, "& & & & & & & ")
    # end

    # # -----------------------------
    # # ---    QCR + QP + Dom
    # logFolder = "./res/Cplex/QCR_QP_Dom"
    # if isfile(logFolder * "/" * inst)
    #     read_QCR_time(logFolder * "/" * inst, fout)
    #     writeLine(logFolder * "/" * inst, fout)
    #     read_nb_dom_cuts(logFolder * "/" * inst, fout)

    # else
    #     print(fout, " & & & & & & & ")
    # end


    # # -----------------------------
    # # ---     QCR2 + QP
    # logFolder = "./res/Cplex/QCR2_QP"
    # if isfile(logFolder * "/" * inst)
    #     read_QCR_time(logFolder * "/" * inst, fout)
    #     writeLine(logFolder * "/" * inst, fout)

    # else
    #     print(fout, " & & & & & & ")
    # end

    # # -----------------------------
    # # ---    QCR2 + QP + Dom
    # logFolder = "./res/Cplex/QCR2_QP_Dom"
    # if isfile(logFolder * "/" * inst)
    #     read_QCR_time(logFolder * "/" * inst, fout)
    #     writeLine(logFolder * "/" * inst, fout)
    #     read_nb_dom_cuts(logFolder * "/" * inst, fout)

    # else
    #     print(fout, " & & & & & & & ")
    # end

    # # -----------------------------
    # # ---    Dom + QCR2 + QP 
    # logFolder = "./res/Cplex/Dom_QCR2_QP"
    # if isfile(logFolder * "/" * inst)
    #     read_nb_dom_cuts(logFolder * "/" * inst, fout)
    #     read_QCR_time(logFolder * "/" * inst, fout)
    #     writeLine(logFolder * "/" * inst, fout)

    # else
    #     print(fout, "& & & & & & & ")
    # end

    # # -----------------------------
    # # ---    Dom + QCR2 + QP + Dom
    # logFolder = "./res/Cplex/Dom_QCR2_QP_Dom"
    # if isfile(logFolder * "/" * inst)
    #     read_nb_dom_cuts(logFolder * "/" * inst, fout)
    #     read_QCR_time(logFolder * "/" * inst, fout)
    #     writeLine(logFolder * "/" * inst, fout)

    # else
    #     print(fout, "& & & & & & & & ")
    # end


    # println(fout, "\\\\")
        
    # close(fout)

end

run(ARGS[1])
# run("./instances_neg/21_2_2019_b.txt")
