---
year: 2010
$12010-CO-17
subject: 计算机组成原理
chapter: 存储系统
knowledge_point: TLB和Cache
type: 选择题
difficulty: 3
frequency: 高频
exam_count: 15
tags: ["计算机组成原理", "TLB和Cache"]
---

# TLB和Cache真题汇总

## 2010年第17题

**元数据**
- 年份：2010年第17题
- 科目：#计算机组成原理
- 知识点：#计算机组成原理/存储系统/TLB
- 难度：⭐⭐⭐
- 关联知识：[知识库/计算机组成原理/TLB](知识库/计算机组成原理/TLB.md)

**题干**

下列命中组合情况中，一次访存过程中不可能发生的是（）。A. TLB 未命中, Cache 未命中, Page 未命中  B. TLB 未命中, Cache 命中, Page 命中  C. TLB 命中, Cache 未命中, Page 命中  D. TLB 命中, Cache 命中, Page 未命中

**答案**：D

**考点分析**
- TLB命中说明页在内存，不可能缺页

---

## 解题思路

### 第一步：题目核心
TLB命中意味着页在内存，与缺页互斥

### 第二步：逐项分析
- ✅ **A. TLB未命中,Cache未命中,Page未命中**（全未命中可能）
- ✅ **B. TLB未命中,Cache命中,Page命中**（TLB刚失效但数据在Cache）
- ✅ **C. TLB命中,Cache未命中,Page命中**（页在内存但数据不在Cache）
- ❌ **D. TLB命中,Cache命中,Page未命中**（矛盾！TLB命中→页在内存→不可能缺页）

### 第三步：答案确认
✅ **D不可能**（TLB命中与缺页矛盾）

## 易错点分析

### 易错点1：认为TLB和缺页独立
❌ 错误理解：TLB只管地址转换，与页是否在内存无关
✅ 正确理解：TLB存储虚实地址映射，只有页在内存时映射才有效。TLB命中→页必在内存→不可能缺页。这是强因果关系

### 易错点2：TLB/Cache/Page三者关系
| 命中情况 | 含义 | 是否可能 |
|---------|------|---------|
| TLB命中 | 页表项在TLB且页在内存 | - |
| Cache命中 | 数据块在Cache | 独立于TLB |
| Page命中 | 页在内存 | TLB命中→必Page命中 |