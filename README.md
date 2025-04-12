# Pegs
跳棋游戏
## How to run:

julia

include("main.jl")

generateInstance(5,5,20) # an example

readInputFile("data/instance_5_5_20.txt")

displaySolution(readInputFile("data/instance_5_5_20.txt"))

