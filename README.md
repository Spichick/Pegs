# Pegs
跳棋游戏
## How to run:

julia

include("main.jl")

generateInstance(5,5,20) # an example
generateDataSet() # 10 random examples

readInputFile("data/instance_5_5_20.txt")

displaySolution(readInputFile("data/instance_5_5_20.txt"))

Note: In io.jl, line 67, you can change the method (normal or heuristique)
