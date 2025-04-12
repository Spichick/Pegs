# This file contains methods to solve an instance (heuristically or with CPLEX)
using CPLEX

include("generation.jl")

TOL = 0.00001

"""
Solve an instance with CPLEX
"""
function cplexSolve(G::Matrix{Int})

    l = size(G, 1) + 4 # size(G,1)表示行数，+4是为了创造虚拟边界
    c = size(G, 2) + 4
        n = 0 
        for i in 1:size(G, 1)
            for j in 1:size(G, 2)
                if G[i, j] == 1
                    n += 1
                end
            end
        end
        println("Il faut ",n-1," marches.")

    model = Model(CPLEX.Optimizer)

    @variable(model, x[1:n, 1:l, 1:c, 1:5], Bin)
    # 最小化棋子的总和值（剩一个子的时候总和最小）
    @objective(model, Min, sum(x[n, i, j, 5] for i in 1:l for j in 1:c))

#************************************************************#
#**********************棋盘外的边界的定义**********************#
#************************************************************#

    # 一. 对于棋盘外新加的边界点
    # 1. 永远无法移动 上下左右四个方向都是0: x[s, i, j, 1:4] = 0
    # 2. 永远存在棋子: x[s, i, j, 5] = 1
    
    # 对于行：
    @constraint(model, [s in 1:n, i in 1:2, j in 1:c], x[s, i, j, 1] == 0)
    @constraint(model, [s in 1:n, i in 1:2, j in 1:c], x[s, i, j, 2] == 0)
    @constraint(model, [s in 1:n, i in 1:2, j in 1:c], x[s, i, j, 3] == 0)
    @constraint(model, [s in 1:n, i in 1:2, j in 1:c], x[s, i, j, 4] == 0)
    @constraint(model, [s in 1:n, i in 1:2, j in 1:c], x[s, i, j, 5] == 1)

    @constraint(model, [s in 1:n, i in (l-1):l, j in 1:c], x[s, i, j, 1] == 0)
    @constraint(model, [s in 1:n, i in (l-1):l, j in 1:c], x[s, i, j, 2] == 0)
    @constraint(model, [s in 1:n, i in (l-1):l, j in 1:c], x[s, i, j, 3] == 0)
    @constraint(model, [s in 1:n, i in (l-1):l, j in 1:c], x[s, i, j, 4] == 0)
    @constraint(model, [s in 1:n, i in (l-1):l, j in 1:c], x[s, i, j, 5] == 1)

    # 对于列：
    @constraint(model, [s in 1:n, i in 1:l, j in 1:2], x[s, i, j, 1] == 0)
    @constraint(model, [s in 1:n, i in 1:l, j in 1:2], x[s, i, j, 2] == 0)
    @constraint(model, [s in 1:n, i in 1:l, j in 1:2], x[s, i, j, 3] == 0)
    @constraint(model, [s in 1:n, i in 1:l, j in 1:2], x[s, i, j, 4] == 0)
    @constraint(model, [s in 1:n, i in 1:l, j in 1:2], x[s, i, j, 5] == 1)

    @constraint(model, [s in 1:n, i in 1:l, j in (c-1):c], x[s, i, j, 1] == 0)
    @constraint(model, [s in 1:n, i in 1:l, j in (c-1):c], x[s, i, j, 2] == 0)
    @constraint(model, [s in 1:n, i in 1:l, j in (c-1):c], x[s, i, j, 3] == 0)
    @constraint(model, [s in 1:n, i in 1:l, j in (c-1):c], x[s, i, j, 4] == 0)
    @constraint(model, [s in 1:n, i in 1:l, j in (c-1):c], x[s, i, j, 5] == 1)

#**************************************************************#
#**********************棋盘内点和边界的定义**********************#
#**************************************************************#

    # 二. 对于棋盘内的边界点
    # " "，是边界
    @constraint(model, [s in 1:n, i in 3:(l-2), j in 3:(c-2); G[i-2, j-2] == -1], x[s, i, j, 1] == 0)
    @constraint(model, [s in 1:n, i in 3:(l-2), j in 3:(c-2); G[i-2, j-2] == -1], x[s, i, j, 2] == 0)
    @constraint(model, [s in 1:n, i in 3:(l-2), j in 3:(c-2); G[i-2, j-2] == -1], x[s, i, j, 3] == 0)
    @constraint(model, [s in 1:n, i in 3:(l-2), j in 3:(c-2); G[i-2, j-2] == -1], x[s, i, j, 4] == 0)
    @constraint(model, [s in 1:n, i in 3:(l-2), j in 3:(c-2); G[i-2, j-2] == -1], x[s, i, j, 5] == 1) 

    # ⭕，是动不了的棋子
    @constraint(model, [i in 3:(l-2), j in 3:(c-2); G[i-2, j-2] == 0], x[1, i, j, 5] == 0) 
    # 🔴，是可以动的棋子
    @constraint(model, [i in 3:(l-2), j in 3:(c-2); G[i-2, j-2] == 1], x[1, i, j, 5] == 1) 

#*****************************************************#
#**********************运动的定义**********************#
#*****************************************************#

# 格子无棋子 (x[s,i,j,5]=0), 这个棋子移动不了 (x[s, i, j, 1:4]必须等于0)
# 格子有棋子 (x[s,i,j,5]=1), 这个棋子可以移动 (x[s, i, j, 1:4]可以等于0或1)

    @constraint(model, [s in 1:(n-1), i in 1:l, j in 1:c, p in 1:4], x[s, i, j, p] <= x[s, i, j, 5])
# 可以向上移动的条件(除去最上行)，即如果我想向上跳(x[s,i,j,1]=1), 那么必须满足
    # 1. 该点上方有棋子(x[s,i-1,j,5]=1)
    # 2. 该点上上方没有棋子(x[s,i-2,j,5]=0)

    # TODO: 想清楚哪个是向上？不确定。
    @constraint(model, [s in 1:(n-1), i in 2:l, j in 1:c], x[s, i, j, 1] <= x[s, i-1, j, 5]) 
    @constraint(model, [s in 1:(n-1), i in 3:l, j in 1:c], x[s, i, j, 1] + x[s, i-2, j, 5] <= 1)
    # @constraint(model, [s in 1:(n-1), i in 3:l, j in 1:c], x[s, i-2, j, 5] == 0)
    # 可以向下移动的条件(除去最下行)
    @constraint(model, [s in 1:(n-1), i in 1:(l-1), j in 1:c], x[s, i, j, 2] <= x[s, i+1, j, 5]) 
    @constraint(model, [s in 1:(n-1), i in 1:(l-2), j in 1:c], x[s, i, j, 2] + x[s, i+2, j, 5] <= 1 ) 

    # 可以向左移动的条件(除去最左列)
    @constraint(model, [s in 1:(n-1), i in 1:l, j in 2:c], x[s, i, j, 3] <= x[s, i, j-1, 5]) 
    @constraint(model, [s in 1:(n-1), i in 1:l, j in 3:c], x[s, i, j, 3] + x[s, i, j-2, 5] <= 1 ) 

    # 可以向右移动的条件(除去最右列)
    @constraint(model, [s in 1:(n-1), i in 1:l, j in 1:(c-1)], x[s, i, j, 4] <= x[s, i, j+1, 5])
    @constraint(model, [s in 1:(n-1), i in 1:l, j in 1:(c-2)], x[s, i, j, 4] + x[s, i, j+2, 5] <= 1 ) 

    # 每次只允许动一步
    @constraint(model, [s in 1:(n-1)], sum(x[s, i, j, p] for i in 1:l, j in 1:c, p in 1:4) <= 1)

    # 更新步骤(s步和s+1步)
    @constraint(model, [s in 1:(n-1), i in 3:(l-2), j in 3:(c-2)], x[s, i, j, 5] - x[s+1, i, j, 5] 
    == x[s, i, j, 1] + x[s, i, j, 2] + x[s, i, j, 3] + x[s, i, j, 4]
    + x[s, i+1, j, 1] - x[s, i+2, j, 1] # 下方的棋子向上跳 - 下下方棋子向上跳 都会影响 (i,j)
    + x[s, i-1, j, 2] - x[s, i-2, j, 2]  
    + x[s, i, j+1, 3] - x[s, i, j+2, 3]
    + x[s, i, j-1, 4] - x[s, i, j-2, 4]) 

    set_optimizer_attribute(model, "CPXPARAM_TimeLimit", 300) 
    optimize!(model)

    res = fill(-1, n, l - 4, c - 4) # 全部填充 -1

    rest = 0

    if primal_status(model) == MOI.FEASIBLE_POINT
        for s in 1:n
            for i in 3:(l-2)
                for j in 3:(c-2)
                    if G[i-2, j-2] == -1 # NOTE: 
                        res[s, i-2, j-2] = -1
                    elseif value.(x[s, i, j, 5]) == 0
                        res[s, i-2, j-2] = 0
                    elseif value.(x[s, i, j, 5]) == 1
                        res[s, i-2, j-2] = 1
                        if s == n
                            rest += 1
                        end
                    end
                end
            end
        end
        return round.(Int, res), n, rest == 1
        #return n
    else
        println("Aucune solution trouvée.")
        return -11
    end

end

"""
Heuristically solve an instance
"""
function heuristicSolve()

    # TODO
    println("In file resolution.jl, in method heuristicSolve(), TODO: fix input and output, define the model")
    
end 

"""
Solve all the instances contained in "../data" through CPLEX and heuristics

The results are written in "../res/cplex" and "../res/heuristic"

Remark: If an instance has previously been solved (either by cplex or the heuristic) it will not be solved again
"""
function solveDataSet()

    dataFolder = "../data/"
    resFolder = "../res/"

    # Array which contains the name of the resolution methods
    resolutionMethod = ["cplex"]
    #resolutionMethod = ["cplex", "heuristique"]

    # Array which contains the result folder of each resolution method
    resolutionFolder = resFolder .* resolutionMethod

    # Create each result folder if it does not exist
    for folder in resolutionFolder
        if !isdir(folder)
            mkdir(folder)
        end
    end
            
    global isOptimal = false
    global solveTime = -1

    # For each instance
    # (for each file in folder dataFolder which ends by ".txt")
    for file in filter(x->occursin(".txt", x), readdir(dataFolder))  
        
        println("-- Resolution of ", file)
        readInputFile(dataFolder * file)

        # TODO
        println("In file resolution.jl, in method solveDataSet(), TODO: read value returned by readInputFile()")
        
        # For each resolution method
        for methodId in 1:size(resolutionMethod, 1)
            
            outputFile = resolutionFolder[methodId] * "/" * file

            # If the instance has not already been solved by this method
            if !isfile(outputFile)
                
                fout = open(outputFile, "w")  

                resolutionTime = -1
                isOptimal = false
                
                # If the method is cplex
                if resolutionMethod[methodId] == "cplex"
                    
                    # TODO 
                    println("In file resolution.jl, in method solveDataSet(), TODO: fix cplexSolve() arguments and returned values")
                    
                    # Solve it and get the results
                    isOptimal, resolutionTime = cplexSolve()
                    
                    # If a solution is found, write it
                    if isOptimal
                        # TODO
                        println("In file resolution.jl, in method solveDataSet(), TODO: write cplex solution in fout") 
                    end

                # If the method is one of the heuristics
                else
                    
                    isSolved = false

                    # Start a chronometer 
                    startingTime = time()
                    
                    # While the t is not solved and less than 100 seconds are elapsed
                    while !isOptimal && resolutionTime < 100
                        
                        # TODO 
                        println("In file resolution.jl, in method solveDataSet(), TODO: fix heuristicSolve() arguments and returned values")
                        
                        # Solve it and get the results
                        isOptimal, resolutionTime = heuristicSolve()

                        # Stop the chronometer
                        resolutionTime = time() - startingTime
                        
                    end

                    # Write the solution (if any)
                    if isOptimal

                        # TODO
                        println("In file resolution.jl, in method solveDataSet(), TODO: write the heuristic solution in fout")
                        
                    end 
                end

                println(fout, "solveTime = ", resolutionTime) 
                println(fout, "isOptimal = ", isOptimal)
                
                # TODO
                println("In file resolution.jl, in method solveDataSet(), TODO: write the solution in fout") 
                close(fout)
            end


            # Display the results obtained with the method on the current instance
            include(outputFile)
            println(resolutionMethod[methodId], " optimal: ", isOptimal)
            println(resolutionMethod[methodId], " time: " * string(round(solveTime, sigdigits=2)) * "s\n")
        end         
    end 
end
