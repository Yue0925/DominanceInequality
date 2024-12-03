include("parserHardKP.jl")

using JuMP, Gurobi


# -----------------------------------------------------------------
# -----------------------------------------------------------------

# function _is_integer(x::Vector{Float64})
#     for i in x 
#         if !(abs(i-1.0) <= 0.0001 || abs(i-0.0) <= 0.0001 )
#             return false
#         end
#     end
#     return true
# end



global model
global best_solution = []


function my_callback_function(cb_data, cb_where)
    global model
    global best_solution

    if cb_where != GRB_CB_MIPNODE # cb_where != GRB_CB_MIPSOL &&
        return
    end

    # You can query a callback attribute using GRBcbget
    if cb_where == GRB_CB_MIPNODE
        valueP = Ref{Cint}()
        GRBcbget(cb_data, cb_where, GRB_CB_MIPNODE_STATUS, valueP)
        if valueP[] != GRB_OPTIMAL
            return  # Solution is something other than optimal.
        end
    end

    # if callback_node_status(cb_data, model) == MOI.CALLBACK_NODE_STATUS_FRACTIONAL

        valueP = Ref{Cdouble}()
        GRBcbget(cb_data, cb_where, GRB_CB_MIPSOL_OBJBND, valueP)
        
        # if valueP[] < best_value
            best_value = valueP[]
            Gurobi.load_callback_variable_primal(cb_data, cb_where)
            best_solution = callback_value.(cb_data, all_variables(model))
            # @info "New upper bound: $best_value   best_solution = $best_solution"
        # end    
    # end
end


function one_swap_ineq1(inst::HKP, i::Int64, j::Int64)
    # todo : x_i ≤ x_j + sum x_d

    O = collect(1:inst.n) ; I = Vector{Int64}() ; allD =  Set{Vector{Int64}}()

    # deleteat!(O, sort([i, j]))

    # set I
    idx = [i, j]
    for o in O
        if o!=i && o!= j && inst.A[o] + inst.A[i] > inst.b
            push!(I, o) ; push!(idx, o)
        end
    end
    deleteat!(O, sort(idx) )


    sort!(O, by = x -> inst.A[x], rev = true)

    # each permutation to avoid fbd 
    # for fbd in 0:length(O)
        D =  Vector{Int64}()
        for o in O 
            # if fbd> 0 && o == O[fbd] 
            #     nothing
            # else 
                push!(D, o)
            # end
            
    
            # sufficient condition  :  w_j + W(N\i\D\I) ≤ W
            W = inst.b 
            for t in 1:inst.n 
                if t == i || t in D || t in I
                    nothing
                else
                    W -= inst.A[t]
                end
            end
    
            if W >= 0
                push!(allD, [i; j; D]) 
                # break
            end
        end
        
    # end
    return allD
end

function one_swap_ineq2(inst::HKP, i::Int64, j::Int64)
    # todo : x_i ≤ x_j + sum x_d

    O = collect(1:inst.n) ; I = Vector{Int64}() ; allD =  Set{Vector{Int64}}()

    # deleteat!(O, sort([i, j]))

    # set I
    idx = [i, j]
    for o in O
        if o!=i && o!= j && inst.A[o] + inst.A[i] > inst.b
            push!(I, o) ; push!(idx, o)
        end
    end
    deleteat!(O, sort(idx) )


    sort!(O, by = x -> inst.A[x], rev = true)

    # each permutation to avoid fbd 
    for fbd in 0:length(O)
        D =  Vector{Int64}()
        for o in O 
            if fbd> 0 && o == O[fbd] 
                nothing
            else 
                push!(D, o)
            end
            
    
            # sufficient condition  :  w_j + W(N\i\D\I) ≤ W
            W = inst.b 
            for t in 1:inst.n 
                if t == i || t in D || t in I
                    nothing
                else
                    W -= inst.A[t]
                end
            end
    
            if W >= 0
                push!(allD, [i; j; D]) ; break
            end
        end
        
    end
    return allD
end

#todo : 
function all_dominance_ineq(inst::HKP)
    ineqs = Vector{Vector{Int64}}()         # x_i ≤ x_j + sum x_d

    for i in 1:inst.n-1
        for j in i+1:inst.n

            # w_i + w_j <= W
            if inst.A[i] + inst.A[j] > inst.b
                continue
            end

            if inst.c[i] < inst.c[j]
                # swap i, j
                all_D = one_swap_ineq2(inst, i, j)
                for inq in all_D
                    push!(ineqs, inq)
                end
           
            elseif inst.c[j] < inst.c[i]
                # swap j, i 
                all_D = one_swap_ineq2(inst, j, i)
                for inq in all_D
                    push!(ineqs, inq)
                end
            end

        end
    end

    # #todo : 
    # println("ineqs : ")
    # for inq in ineqs
    #     println(inq )
    # end
    return ineqs
end



function mip_solve(inst::HKP, fname)
    model = Model(Gurobi.Optimizer)  ; JuMP.set_silent(model)

    @variable(model, x[1:inst.n], Bin )
    @objective(model, Max, x'* inst.c)

    @constraint(model, x'* inst.A ≤ inst.b)

    optimize!(model)

   if termination_status(model)== OPTIMAL
    sol = value.(x)
    obj = sol'* inst.c 
    fout = open(fname, "a")
    println(fout, "opt_val = ", round(obj, digits = 4))
    close(fout)
   else
        error("no OPT sol ", inst.name)
   end



end

function one_solve(inst::HKP, cut::Bool, fname)
    global best_solution = []


    global model = Model(Gurobi.Optimizer)  #; JuMP.set_silent(model)
    set_optimizer_attribute(model, "LogFile", fname)

    @variable(model, x[1:inst.n], Bin )
    @objective(model, Max, x'* inst.c)

    @constraint(model, x'* inst.A ≤ inst.b)

    nb_dom_cuts=0
    # # todo brut force tout ineq 1) 
    if cut
        ineqs = all_dominance_ineq(inst) ; nb_dom_cuts = length(ineqs)
        for inq in ineqs
            @constraint(model, x[inq[1]] ≤ sum( x[i] for i in inq[2:end]) )
        end
    end
    
    # todo : turn off parameters 
    # set_optimizer_attribute(model, "CPX_PARAM_CLIQUES", -1)
    # set_optimizer_attribute(model, "CPXPARAM_MIP_Cuts_LiftProj", -1)
    # set_optimizer_attribute(model, "CPX_PARAM_LANDPCUTS", -1)
    # set_optimizer_attribute(model, "CPX_PARAM_COVERS", -1)
    # set_optimizer_attribute(model, "CPX_PARAM_DISJCUTS", -1)
    # set_optimizer_attribute(model, "CPX_PARAM_FLOWCOVERS", -1)
    # set_optimizer_attribute(model, "CPX_PARAM_FLOWPATHS", -1)
    # set_optimizer_attribute(model, "CPX_PARAM_FRACCUTS", -1)
    # set_optimizer_attribute(model, "CPX_PARAM_GUBCOVERS", -1)
    # set_optimizer_attribute(model, "CPX_PARAM_ZEROHALFCUTS", -1)
    # set_optimizer_attribute(model, "CPX_PARAM_MIRCUTS", -1)
    # set_optimizer_attribute(model, "CPX_PARAM_IMPLBD", -1)
    # set_optimizer_attribute(model, "CPX_PARAM_CUTPASS", -1)

    # set_optimizer_attribute(model, "CPX_PARAM_FPHEUR", -1)
    # set_optimizer_attribute(model, "CPX_PARAM_PROBE", -1)
    # set_optimizer_attribute(model, "CPX_PARAM_HEURFREQ", -1)
    # set_optimizer_attribute(model, "CPX_PARAM_RINSHEUR", -1)


    # set_optimizer_attribute(model, "CPX_PARAM_PREIND", 0)
    # set_optimizer_attribute(model, "CPX_PARAM_AGGIND", 0)
    # set_optimizer_attribute(model, "CPX_PARAM_RELAXPREIND", 0)
    # set_optimizer_attribute(model, "CPX_PARAM_PREPASS", 0)
    # set_optimizer_attribute(model, "CPX_PARAM_REPEATPRESOLVE", 0)
    # set_optimizer_attribute(model, "CPX_PARAM_BNDSTRENIND", 0)
    # set_optimizer_attribute(model, "CPX_PARAM_COEREDIND", 0)
    # set_optimizer_attribute(model, "CPX_PARAM_REDUCE", 0)
    # set_optimizer_attribute(model, "CPXPARAM_Preprocessing_Symmetry", 0)

    
    #todo :  Gurobi parameters 
    set_attribute(model, "Presolve", 0)
    set_attribute(model, "AggFill", -1)
    set_attribute(model, "Aggregate", 0)
    set_attribute(model, "Heuristics", 0)
    set_attribute(model, "LPWarmStart", 0)
    set_attribute(model, "NLPHeur", 0)
    set_attribute(model, "NoRelHeurTime", 0)
    set_attribute(model, "PreCrush", 0)
    set_attribute(model, "PreDepRow", 0)
    set_attribute(model, "PreDual", 0)
    set_attribute(model, "PrePasses", -1)
    set_attribute(model, "RINS", 0)
    set_attribute(model, "Symmetry", 0)



    set_optimizer_attribute(model, "NodeLimit", 1)

    MOI.set(model, MOI.NumberOfThreads(), 1) # todo 
    MOI.set(model, Gurobi.CallbackFunction(), my_callback_function)



    optimize!(model)
    solved_time = solve_time(model) 

    # set_optimizer_attribute(model, "DisplayInterval", 1)

    obj = nothing
    opt = termination_status(model)== OPTIMAL

    if is_solved_and_feasible(model)
        sol = value.(x)
        gap = relative_gap(model) 

        if gap == 0.0
            obj = sol'* inst.c 
            println( "gap = $(gap) \t obj = $obj \t x = $sol \t nb_dom_cuts=$nb_dom_cuts" )
        end
    elseif length(best_solution) >0
        obj = best_solution'* inst.c 
        println( " obj = $obj \t x = $best_solution \t nb_dom_cuts=$nb_dom_cuts" )
    else
        @warn "no sol found in callback ! "
    end

    println(" ----------------------------- \n\n")

    fout = open(fname, "a")
    println(fout, "opt = $opt")
    println(fout, "obj = ", round(obj, digits=4))

    if cut println(fout, "nb_dom_cuts = $nb_dom_cuts") end 

    println(fout, "solved_time = ", round(solved_time, digits=4))
    close(fout)

    return obj,opt
end


function run(fname::String)
    
    instances = readHKP(fname)

    folder = "./res/"
    if !isdir(folder)
        mkdir(folder)
    end

    folder = "./res/"* split( split(fname, "/")[end], "." )[1] * "/"
    if !isdir(folder)
        mkdir(folder)
    end


    idx = 0 ; cut_succ = 0 ; cut_failed = 0
    

    for inst in instances
        idx += 1

        # #todo : 
        # idx = 91
        # inst = instances[idx]

        println("\n -----------------------------")
        println(" solving idx = $(idx) $(inst.name) ... ")
        # println("n = $(inst.n)\n A = $(inst.A) \n b=$(inst.b) \n c=$(inst.c)")
        println(" -----------------------------")

        subfolder = folder * inst.name * "/"
        if !isdir(subfolder)
            mkdir(subfolder)
        end

        lp, opt = one_solve(inst, false, subfolder * "grb.log")

        if opt
            continue            
        end

        lp_, opt = one_solve(inst, true, subfolder * "grb_dom.log")
        mip_solve(inst, subfolder * "grb_dom.log")

        if round(lp, digits = 4) != round(lp_ , digits=4)
            cut_succ += 1
            @warn "proved !! idx = $idx \t cut_succ = $cut_succ"
        else
            cut_failed +=1
            @info "failed cut_failed = $cut_failed"
        end

    end


end






function readLPvalue(fname)
    f = open(fname, "r") ; lp = 0.0

    for lines in readlines(f)
        line = split(lines, " ")

        # Root relaxation:
        if line[1] == "Root" && line[2] == "relaxation:"
            lp = round(parse(Float64, split(line[4], ",")[1] ), digits = 4)
        end
    end

    close(f)
    return lp
end


function readNumCuts(fname)
    f = open(fname, "r") ; nb_cuts = 0
    count = false

    for lines in readlines(f)
        line = split(lines, " ")
         
        if line[1] == "Cutting" && line[2] == "planes:"
            count = true ; continue
        end

        if count && length(line)==1
            count = false ; break
        end
        if count
            nb_cuts += parse(Int64, line[end])
        end
    end

    close(f)
    return nb_cuts
end


function readObj(fname)
    f = open(fname, "r") ; lp = 0.0

    for lines in readlines(f)
        line = split(lines, " ")

        # Root relaxation:
        if line[1] == "obj"
            lp = round(parse(Float64, line[end] ), digits = 4)
        end
    end

    close(f)
    return lp
end

function readOptVal(fname)
    f = open(fname, "r") ; opt_val = 0.0

    for lines in readlines(f)
        line = split(lines, " ")

        # Root relaxation:
        if line[1] == "opt_val"
            opt_val = round(parse(Float64, line[end] ), digits = 4)
        end
    end

    close(f)
    return opt_val
end

function readTime(fname)
    f = open(fname, "r") ; solved_time = 0.0

    for lines in readlines(f)
        line = split(lines, " ")

        # Root relaxation:
        if line[1] == "solved_time"
            solved_time = round(parse(Float64, line[end] ), digits = 4)
        end
    end

    close(f)
    return solved_time
end


function readDomcuts(fname)
    f = open(fname, "r") ; nb_dom_cuts = 0

    for lines in readlines(f)
        line = split(lines, " ")

        # Root relaxation:
        if line[1] == "nb_dom_cuts"
            nb_dom_cuts = parse(Int64, line[end] )
        end
    end

    close(f)
    return nb_dom_cuts
end

function write_line(fout, folder, subfolder)
    f = open(fout, "a")
    
    print(f, subfolder, " & ")  # name

    file = folder * "/"* subfolder * "/grb.log"
    print(f, readLPvalue(file) , " & " )  #   lp 
    
    obj = readObj(file)
    print(f, obj , " & " )    # grb value 

    opti = readOptVal(folder * "/"* subfolder * "/grb_dom.log")
    gap_lp = round(abs(opti- obj )/opti * 100 , digits = 4) 
    print(f, gap_lp , " & " )    # grb to integer gap

    print(f, readNumCuts(file), " & " )     # grb #cuts 

    print(f, readTime(file), " & " )           # grb time


    file = folder * "/"* subfolder * "/grb_dom.log"

    newobj = readObj(file)
    print(f, newobj , " & " )    # grb+dom value 


    gap_dom = round(abs(opti- newobj )/opti * 100 , digits = 4) 
    print(f, gap_dom , " & " )    # grb+dom to integer gap


    gap = round(abs(newobj- obj )/obj * 100 , digits = 4) 
    print(f, gap , " & " )    # + gap % 


    gap_rel = round(abs(obj- newobj )/opti * 100 , digits = 4) 
    print(f, gap_rel , " & " )    # improv to integer gap


    print(f, readNumCuts(file) + readDomcuts(file), " & " )     # grb #cuts + dom cuts

    println(f, readTime(file), " \\\\ " )           # grb time
    close(f)
end


function writeTab(fname)
    tab_name = "./tabs/" * split( split(fname, "/")[end], "." )[1]
    if !isdir("./tabs/")
        mkdir("./tabs/")
    end
    folder = "./res/" * split( split(fname, "/")[end], "." )[1] * "/"

    for subfolder in readdir(folder)
        println(subfolder, " : ")
        if length(readdir(folder *"/" * subfolder) ) <=1
            continue
        end

        write_line(tab_name, folder ,subfolder)
    end

end

run("./hardinstances_pisinger/knapPI_11_50_1000.csv")

# | kp | n | PL val - time | PL + dom val(%) - cuts - time | Gurobi root val(%) - cuts - time | Gurobi root + dom val(%) - cuts - time 
writeTab("./hardinstances_pisinger/knapPI_11_50_1000.csv")


#n=20  28 vs 9
#n=50 48 vs 15
#n=100 killed (around nb_dom_cuts=64828 nb_dom_cuts=143733)
