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
        println("Théoriquement, il faut au maximum ",n-1," marches.")

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

    # ⭕，是空
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
function heuristicSolve(G::Matrix{Int})
    # 获取棋盘原始尺寸
    rows, cols = size(G)
    # 计算初始棋子数
    n = sum(G .== 1)
    println("Il faut au maximum ", n-1, " steps.")

    l = rows + 4
    c = cols + 4
    # init
    board = fill(-1, l, c)
    for i in 1:rows
        for j in 1:cols
            board[i+2, j+2] = G[i, j]
        end
    end
    
    # 初始化结果数组
    res = fill(-1, n, rows, cols)
    for i in 1:rows
        for j in 1:cols
            res[1, i, j] = G[i, j]
        end
    end
    
    # 合法方向：上、下、左、右, (di,dj): 起始位置到目标位置, (mi,mj): 起始位置到中间位置
    directions = [(-2, 0, -1, 0), (2, 0, 1, 0), (0, -2, 0, -1), (0, 2, 0, 1)]
    
    # 计算后续跳跃潜力
    function evaluate_future_moves(temp_board, l, c) 
        future_moves = 0
        for i in 3:(l-2) # 遍历棋盘内的点，记录所有可能的跳跃
            for j in 3:(c-2)
                if temp_board[i, j] != 1
                    continue
                end
                for (di, dj, mi, mj) in directions # 起始位置是1
                    ni, nj = i + di, j + dj
                    mid_i, mid_j = i + mi, j + mj
                    if 1 <= ni <= l && 1 <= nj <= c &&
                        1 <= mid_i <= l && 1 <= mid_j <= c &&
                        temp_board[mid_i, mid_j] == 1 && temp_board[ni, nj] == 0 # 中间位置是1，终点位置是0
                        future_moves += 1
                    end
                end
            end
        end
        return future_moves
    end
    
    # 回溯搜索函数
    function search(board, s, res, best_res, best_remaining, max_depth=n-1)
        ### 1. 终止条件
        if s >= n || max_depth <= 0
            remaining = sum(board[3:(l-2), 3:(c-2)] .== 1)
            if remaining < best_remaining[1] # objective: 最小化剩余棋子数
                best_remaining[1] = remaining
                for t in 1:n
                    for i in 1:rows
                        for j in 1:cols
                            best_res[t, i, j] = res[t, i, j]
                        end
                    end
                end
            end
            return
        end

        ### 2. 计算可能的条约
        # 收集可能的跳跃
        possible_moves = []
        for i in 3:(l-2)
            for j in 3:(c-2)
                if board[i, j] != 1
                    continue
                end
                for (di, dj, mi, mj) in directions
                    ni, nj = i + di, j + dj
                    mid_i, mid_j = i + mi, j + mj
                    if 1 <= ni <= l && 1 <= nj <= c &&
                        1 <= mid_i <= l && 1 <= mid_j <= c &&
                        board[mid_i, mid_j] == 1 && board[ni, nj] == 0
                        # 计算启发式分数
                        temp_board = copy(board)
                        temp_board[i, j] = 0
                        temp_board[mid_i, mid_j] = 0
                        temp_board[ni, nj] = 1
                        future_score = evaluate_future_moves(temp_board, l, c)
                        center_dist = abs((ni - l/2)^2 + (nj - c/2)^2) # 鼓励棋子跳到中间位置(距离中心的平方)，因为棋子越靠近中心越有概率和其他棋子相互跳跃。
                        score = future_score * 10 + 1 / (center_dist + 1)
                        push!(possible_moves, (i, j, ni, nj, score))
                    end
                end
            end
        end

        # 3. 按分数排序，尝试前几个跳跃
        sort!(possible_moves, by=x->x[5], rev=true) # 根据第五个元素即score排序, rev: 降序
        for (i, j, ni, nj, _) in possible_moves[1:min(3, length(possible_moves))] # 只尝试前3个跳跃，加速
            # 执行跳跃
            new_board = copy(board)
            new_board[i, j] = 0
            new_board[i + div(ni - i, 2), j + div(nj - j, 2)] = 0 # 中间位置
            new_board[ni, nj] = 1
            # 更新 res
            new_res = copy(res)
            new_res[s+1, :, :] = new_board[3:(l-2), 3:(c-2)]
            # 递归搜索
            search(new_board, s+1, new_res, best_res, best_remaining, max_depth-1)
        end
    end
    
    # 初始化最佳结果
    best_res = copy(res)
    best_remaining = [n]  # 使用数组以便修改
    # 运行搜索
    search(board, 1, res, best_res, best_remaining)
    
    # 计算最终剩余棋子
    remaining_pegs = best_remaining[1]
    println("启发式方法剩余棋子数: ", remaining_pegs)
    
    return best_res, n, remaining_pegs == 1
end