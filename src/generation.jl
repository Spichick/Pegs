# This file contains methods to generate a data set of instances (i.e., sudoku grids)
include("io.jl")

"""
Generate an n*n grid with a given density

Argument
- n: size of the grid
- density: percentage in [0, 1] of initial values in the grid
"""
# function generateInstance(n::Int64, min_moves::Int64=2)
#     board = fill('0', n, n)
#     #le reste est le même...
# end

function generateInstance(l::Int64, c::Int64, min_moves::Int64=2)
    # 初始化棋盘
    board = fill('0', l, c)
    
    # 设置中心为 '1'
    center_row = l ÷ 2 + 1
    center_col = c ÷ 2 + 1
    board[center_row, center_col] = '1'
    
    # 跳跃方向：上、下、左、右
    directions = [(-2, 0), (2, 0), (0, -2), (0, 2)]
    # TODO: 尝试更随机的生成边界
    # 逆向跳跃生成棋子
    move_count = 0
    while move_count < min_moves
        possible_moves = []
        for i in 1:l
            for j in 1:c
                if board[i,j] == '0' || board[i,j] == '1'
                    for (di, dj) in directions
                        # 终点位置
                        to_i = i + di 
                        to_j = j + dj
                        # 中间位置
                        mid_i = i + di ÷ 2
                        mid_j = j + dj ÷ 2
                        if 1 <= to_i <= l && 1 <= to_j <= c && # 终点在棋盘内 
                            board[to_i, to_j] == '1' && # 终点必须有子
                            board[mid_i, mid_j] == '0' && # 中间格子必须是空
                            board[i, j] == '0' # 起点必须是空
                            push!(possible_moves, (i,j,di,dj,mid_i,mid_j))
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
        i, j, di, dj, mid_i, mid_j = move
        board[i,j] = '1'
        board[mid_i, mid_j] = '1'
        board[i + di, j + dj] = '0'
        
        move_count += 1
    end
    # 统计 '1' 的数量
    #num_pegs = sum(board .== '1')
    #if num_pegs == 3
    #    println("Faux")
    #    return 0
    #elseif num_pegs == 4
    #    println("Vrai")
    #end
    
        
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

function generateInstanceWithIndex(l::Int64, c::Int64, min_moves::Int64=2, index::Int64=1)
    # 初始化棋盘
    board = fill('0', l, c)
    # TODO: 创建一个棋盘用来记录左所有走过的点，如果棋盘过大，把没走过的点算成障碍物
    # board_flag = fill('2', l, c)
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
                        # 终点位置
                        to_i = i + di 
                        to_j = j + dj
                        # 中间位置
                        mid_i = i + di ÷ 2
                        mid_j = j + dj ÷ 2
                        if 1 <= to_i <= l && 1 <= to_j <= c && # 终点在棋盘内 
                            board[to_i, to_j] == '1' && # 终点必须有子
                            board[mid_i, mid_j] == '0' # 中间格子必须是空
                            board[i, j] == '0' # 起点必须是空
                            push!(possible_moves, (i,j,di,dj, mid_i, mid_j))
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
        i, j, di, dj, mid_i, mid_j = move
        board[i,j] = '1'
        board[mid_i, mid_j] = '1'
        board[i + di, j + dj] = '0'
        
        move_count += 1
    end
    filename = "data/instance_$(index).txt"
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
end

"""
Generate all the instances

Remark: a grid is generated only if the corresponding output file does not already exist
"""
function clearDataFolder()
    # 设置 data 文件夹路径
    data_dir = "data"

    # 如果文件夹存在，则删除其中的所有文件
    if isdir(data_dir)
        # 获取文件夹内所有文件
        files = readdir(data_dir)
        for file in files
            # 删除每个文件
            rm(joinpath(data_dir, file))
        end
    else
        # 如果文件夹不存在，则创建它
        mkdir(data_dir)
    end
end

function generateDataSet() # 生成10个数据集
    clearDataFolder()
    lists = [4 ,5, 6, 7, 8]
    num = 10
    i = 1
    while(i <= num)
        l = rand(lists)
        c = rand(lists)
        min_moves = rand(2:l * c - 1)
        generateInstanceWithIndex(l, c, min_moves, i)

        i += 1
    end
end

function g() # 测试溢出 5x5,3: 01110
    i=0
    while(i<1000000)
        i=i+1
        generateInstance(5,5,3)
    end
end


