# This file contains methods to generate a data set of instances (i.e., sudoku grids)
include("io.jl")

"""
Generate an n*n grid with a given density

Argument
- n: size of the grid
- density: percentage in [0, 1] of initial values in the grid
"""
function generateInstance(l::Int64, c::Int64, min_moves::Int64=2)
    # 初始化棋盘
    board = fill('0', l, c)
    
    # 设置中心为 '1'
    center_row = l ÷ 2 + 1
    center_col = c ÷ 2 + 1
    board[center_row, center_col] = '1'
    
    # 跳跃方向：上、下、左、右
    directions = [(-2, 0), (2, 0), (0, -2), (0, 2)]
    
    # 逆向跳跃生成棋子
    move_count = 0
    while move_count < min_moves
        possible_moves = []
        for i in 1:l
            for j in 1:c
                if board[i,j] == '0' || board[i,j] == '1'
                    for (di, dj) in directions
                        to_i = i + di
                        to_j = j + dj
                        mid_i = i + di ÷ 2
                        mid_j = j + dj ÷ 2
                        if 1 <= to_i <= l && 1 <= to_j <= c && 
                            board[to_i, to_j] == '1' && # 终点必须有子
                            board[mid_i, mid_j] == '0' # 中间格子必须是空
                            push!(possible_moves, (i,j,di,dj))
                        end
                    end
                end
            end
        end
        
        if isempty(possible_moves)
            break
        end
        # 更新
        move = rand(possible_moves)
        i, j, di, dj = move
        board[i,j] = '1'
        board[i + di ÷ 2, j + dj ÷ 2] = '1'
        board[i + di, j + dj] = '0'
        
        move_count += 1
    end
    
    # 保存到文件
    filename = "data/instance_$(l)_$(c)_$(min_moves).txt"
    open(filename, "w") do file
        for i in 1:l
            for j in 1:c
                write(file, board[i,j])
                if j < c
                    write(file, ",")
                end
            end
            write(file, "\n")
        end
    end
    
    println("Successfully saved at $filename")
    return board
end
"""
Generate all the instances

Remark: a grid is generated only if the corresponding output file does not already exist
"""
function generateDataSet()

    # TODO
    println("In file generation.jl, in method generateDataSet(), TODO: generate an instance")
    
end



