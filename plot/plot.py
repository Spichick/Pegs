import matplotlib.pyplot as plt

# 原始数据
time_before_acceleration = [
    0.05924 ,
0.13368 ,
0.28561 ,
0.54332 ,
2.66913 ,
3.29757 ,
3.61567 ,
5.16449 ,
8.21849 

]

# 加速后的数据
time_after_acceleration = [
    0.00090 ,
0.00240 ,
0.00257 ,
0.02702 ,
0.00380 ,
0.33526 ,
0.48837 ,
0.38724 ,
0.87652 

]
res = [
    0.05924/0.00090, 0.13368/0.00240, 0.28561/0.00257, 
    0.54332/0.02702, 2.66913/0.00380, 3.29757/0.33526, 
    3.61567/0.48837, 5.16449/0.38724
]
avg_res = sum(res) / len(res)
print("加速比：", res)
print("平均加速比：", avg_res)
# x轴：数据点索引
x = range(1, 10)

# 绘制点图，不连接点
plt.scatter(x, time_before_acceleration, label='Normal', marker='o')
plt.scatter(x, time_after_acceleration, label='Heuristique', marker='x')
#plt.yscale('log')
# 设置纵坐标范围
plt.ylim(0, 9)

# 添加标签和标题
plt.xlabel('Instance')
plt.ylabel('Temps (s)')
plt.title('SpeedUp')

# 显示图例
plt.legend()

# 展示图形
plt.show()
plt.savefig("plot.png")