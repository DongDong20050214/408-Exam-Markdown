"""
408真题考点自动标注工具

功能：基于题干关键词自动推断考点并生成标注文件

使用方法：
1. python annotate_questions.py <年份>
2. 输出到 02-按知识点-选择题/ 目录
"""

import re
import json

# 考点关键词映射
KNOWLEDGE_MAP = {
    # 数据结构 - 线性表
    "ds/list/array": ["顺序表", "连续存储", "数组"],
    "ds/list/linked/single": ["单链表", "链表", "结点", "指针", "next", "头结点", "尾结点"],
    "ds/list/linked/double": ["双向链表", "双链表", "prior", "前驱", "后继"],
    "ds/list/linked/circular": ["循环链表"],
    "ds/list/static": ["静态链表"],

    # 数据结构 - 栈队列串
    "ds/stack/application": ["栈", "入栈", "出栈", "push", "pop", "括号匹配"],
    "ds/stack/expression": ["表达式", "后缀", "前缀", "中缀", "逆波兰"],
    "ds/queue/application": ["队列", "入队", "出队", "enqueue", "dequeue"],
    "ds/queue/circular": ["循环队列", "队满", "队空"],
    "ds/string/kmp": ["KMP", "next数组", "模式匹配", "串"],

    # 数据结构 - 树
    "ds/tree/traverse": ["遍历", "前序", "中序", "后序", "层次"],
    "ds/tree/bst": ["二叉搜索树", "二叉排序树", "BST"],
    "ds/tree/avl": ["平衡二叉树", "AVL", "平衡因子"],
    "ds/tree/threaded": ["线索二叉树", "线索化"],
    "ds/tree/huffman": ["哈夫曼", "Huffman", "最优二叉树"],
    "ds/tree/forest": ["森林", "树转二叉树", "左孩子右兄弟"],

    # 数据结构 - 图
    "ds/graph/storage": ["邻接矩阵", "邻接表", "邻接多重表", "十字链表"],
    "ds/graph/traverse": ["DFS", "BFS", "深度优先", "广度优先"],
    "ds/graph/shortest": ["最短路径", "Dijkstra", "Floyd", "Bellman-Ford"],
    "ds/graph/mst": ["最小生成树", "Prim", "Kruskal"],
    "ds/graph/topo": ["拓扑排序", "AOV", "AOE", "关键路径"],

    # 数据结构 - 查找排序
    "ds/search/sequential": ["顺序查找"],
    "ds/search/binary": ["折半查找", "二分查找"],
    "ds/search/hash": ["散列", "哈希", "hash", "冲突", "装填因子"],
    "ds/sort/insert": ["插入排序", "直接插入"],
    "ds/sort/shell": ["希尔排序"],
    "ds/sort/bubble": ["冒泡排序"],
    "ds/sort/quick": ["快速排序", "枢轴", "pivot"],
    "ds/sort/select": ["选择排序"],
    "ds/sort/heap": ["堆排序", "大根堆", "小根堆", "最大堆", "最小堆"],
    "ds/sort/merge": ["归并排序", "归并"],
    "ds/sort/radix": ["基数排序"],
    "ds/sort/external": ["外排序", "多路归并", "败者树"],

    # 计算机组成原理
    "co/data/integer": ["补码", "原码", "反码", "定点数"],
    "co/data/float": ["浮点数", "IEEE 754", "阶码", "尾数"],
    "co/storage/cache": ["Cache", "缓存", "命中率"],
    "co/storage/cache/mapping": ["直接映射", "全相联", "组相联"],
    "co/storage/virtual": ["虚拟存储", "虚拟内存", "TLB", "页表"],
    "co/storage/page": ["分页", "页框", "页号"],
    "co/instruction/format": ["指令格式", "操作码", "地址码"],
    "co/instruction/addressing": ["寻址方式", "立即寻址", "直接寻址", "间接寻址"],
    "co/cpu/pipeline": ["流水线", "冒险", "数据冒险", "控制冒险"],
    "co/io/interrupt": ["中断", "中断向量", "中断处理"],
    "co/io/dma": ["DMA", "直接存储器访问"],

    # 操作系统
    "os/process/concept": ["进程", "线程", "PCB"],
    "os/process/schedule": ["调度", "时间片", "优先级", "轮转"],
    "os/process/sync": ["同步", "互斥", "临界区"],
    "os/process/semaphore": ["信号量", "PV操作", "wait", "signal"],
    "os/process/deadlock": ["死锁", "资源分配图", "银行家算法"],
    "os/memory/paging": ["分页", "页表", "页框"],
    "os/memory/virtual": ["虚拟内存", "缺页", "页面置换"],
    "os/memory/replacement": ["LRU", "FIFO", "OPT", "置换算法"],
    "os/file/system": ["文件系统", "目录", "inode"],
    "os/file/disk": ["磁盘调度", "SCAN", "SSTF", "FCFS"],

    # 计算机网络
    "net/physical/encoding": ["编码", "曼彻斯特", "差分曼彻斯特"],
    "net/datalink/flow": ["流量控制", "滑动窗口"],
    "net/datalink/csma": ["CSMA", "CSMA/CD", "CSMA/CA"],
    "net/datalink/vlan": ["VLAN", "虚拟局域网"],
    "net/network/ip": ["IP地址", "子网", "子网掩码"],
    "net/network/routing": ["路由", "路由算法", "距离向量", "链路状态"],
    "net/network/rip": ["RIP"],
    "net/network/ospf": ["OSPF"],
    "net/network/bgp": ["BGP"],
    "net/transport/tcp": ["TCP", "三次握手", "四次挥手"],
    "net/transport/flow": ["流量控制", "拥塞控制", "慢开始"],
    "net/transport/udp": ["UDP", "用户数据报"],
    "net/application/http": ["HTTP", "GET", "POST"],
    "net/application/dns": ["DNS", "域名解析"],
}

# 难度评估规则
def estimate_difficulty(text):
    """根据题干长度和复杂度估算难度"""
    length = len(text)
    if "下列" in text and "正确" in text:
        return "⭐⭐"  # 判断题中等
    if length < 150:
        return "⭐"
    elif length < 300:
        return "⭐⭐"
    elif length < 500:
        return "⭐⭐⭐"
    else:
        return "⭐⭐⭐⭐"

# 识别考点
def identify_knowledge_points(text):
    """识别题干中的考点"""
    found = []
    for kid, keywords in KNOWLEDGE_MAP.items():
        for keyword in keywords:
            if keyword in text:
                found.append(kid)
                break
    return list(set(found))  # 去重

# 生成标签
def generate_tags(knowledge_ids):
    """将知识点ID转换为标签"""
    tags = []
    for kid in knowledge_ids:
        # 转换格式: ds/list/linked/single -> #数据结构/线性表/单链表
        parts = kid.split('/')
        if parts[0] == 'ds':
            tag = '#数据结构'
        elif parts[0] == 'co':
            tag = '#计算机组成原理'
        elif parts[0] == 'os':
            tag = '#操作系统'
        elif parts[0] == 'net':
            tag = '#计算机网络'

        # 添加详细路径
        for part in parts[1:]:
            tag += '/' + part
        tags.append(tag)
    return tags

# 主函数
def annotate_question(year, qnum, question_text, options, answer=None):
    """标注单个题目"""

    kps = identify_knowledge_points(question_text)
    difficulty = estimate_difficulty(question_text)
    tags = generate_tags(kps)

    # 生成markdown
    md = f"""## {year}年第{qnum:02d}题

**元数据**
- 年份：[[../../01-真题原卷/{year}年408真题#{qnum:02d}|{year}年第{qnum}题]]
- 知识点：{' '.join(tags)}
- 难度：{difficulty}
- 关联知识：{' '.join([f'[[知识库/{kid}]]' for kid in kps])}

**题干**

{question_text}

{options}

**答案**：{answer if answer else '【待补充】'}

**考点分析**
【待人工补充】

---

"""
    return md

if __name__ == "__main__":
    print("408真题考点自动标注工具")
    print("使用示例：python annotate_questions.py 2024")
