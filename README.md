# Pegs

# 跳棋游戏

## How to run:

    julia

    include("main.jl")

### If you want to generate one specific instance.

    generateInstance(5,5,20) 

### If you want to generate 10 random instances.
    generateDataSet() 

### If you want to display the instance's matrix.

    readInputFile("data/instance_5_5_20.txt")

### If you want to display an instance.

    displayGrid(readInputFile("future_jump_ins.txt"))

### If you want to display the solution with the process.

    displaySolution(readInputFile("data/instance_5_5_20.txt"))


Note: In io.jl, line 67, you can change the method (normal or heuristique)
