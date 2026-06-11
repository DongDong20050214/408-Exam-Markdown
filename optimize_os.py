# -*- coding: utf-8 -*-
"""
批量优化操作系统选择题
按照AI优化标准模板优化文件
"""

import os
import re
from pathlib import Path

# 基础路径
BASE_PATH = r"C:\Users\86172\Documents\Obsidian Vault\408真题知识库\408题库\02-按知识点-选择题\操作系统"

# 知识点考频映射
EXAM_FREQUENCY_MAP = {
    "系统调用": ("高频", 10),
    "中断": ("高频", 15),
    "用户态": ("高频", 12),
    "内核态": ("高频", 12),
    "特权指令": ("高频", 8),
    "进程": ("高频", 20),
    "线程": ("高频", 15),
    "调度": ("高频", 18),
    "死锁": ("高频", 16),
    "信号量": ("高频", 12),
    "互斥": ("高频", 14),
    "同步": ("高频", 12),
    "银行家": ("高频", 8),
    "页表": ("高频", 15),
    "页面置换": ("高频", 14),
    "LRU": ("高频", 10),
    "虚拟内存": ("高频", 12),
    "分页": ("高频", 15),
    "缺页": ("高频", 10),
    "文件": ("高频", 12),
    "索引": ("高频", 10),
    "磁盘": ("高频", 14),
    "分段": ("中频", 7),
    "TLB": ("中频", 5),
    "位图": ("中频", 6),
    "IO": ("中频", 7),
    "DMA": ("中频", 5),
    "缓冲": ("中频", 6),
}

def extract_year(filename):
    """从文件名提取年份"""
    m = re.match(r'(\d{4})年', filename)
    return int(m.group(1)) if m else None

def extract_number(filename):
    """从文件名提取题号"""
    m = re.search(r'第(\d+)题', filename)
    return int(m.group(1)) if m else None

def get_difficulty(content, kp):
    """判断难度"""
    if any(w in content for w in ["计算", "推导", "银行家", "页面置换算法"]):
        return 4
    elif any(w in content for w in ["分析", "比较"]):
        return 3
    else:
        return 2

def get_exam_info(kp):
    """获取考频"""
    for key, val in EXAM_FREQUENCY_MAP.items():
        if key in kp:
            return val
    return ("中频", 5)

def has_image(content):
    """检查图片"""
    return bool(re.search(r'!\[.*?\]\(.*?\)', content))

def process_file(filepath):
    """处理单个文件"""
    try:
        content = filepath.read_text(encoding='utf-8')

        # 检查frontmatter
        m = re.match(r'^---\n(.*?)\n---\n(.*)$', content, re.DOTALL)
        if not m:
            print(f"  [跳过] 无frontmatter: {filepath.name}")
            return None

        fm, body = m.group(1), m.group(2)

        # 已优化？
        if "year:" in fm and "question_id:" in fm:
            return "skip"

        # 提取信息
        year = extract_year(filepath.name)
        num = extract_number(filepath.name)

        if not year or not num:
            print(f"  [跳过] 无法识别: {filepath.name}")
            return None

        # 提取知识点
        kp_m = re.search(r'knowledge_point:\s*(.+)', fm)
        kp = kp_m.group(1).strip() if kp_m else ""

        # 判断属性
        diff = get_difficulty(content, kp)
        freq, count = get_exam_info(kp)
        img = has_image(content)

        # 构建新frontmatter
        new_fm = fm.rstrip() + f"""

# ===== 以下为AI优化新增字段 =====
year: {year}
question_id: "{year}-OS-{num:02d}"
difficulty: {diff}
exam_frequency: "{freq}"
exam_count: {count}
has_image: {str(img).lower()}
related_questions: []
related_knowledge: []"""

        # 添加分析章节
        if "## 解题思路" not in body:
            body += """

## 解题思路

### 第一步：明确题目要求
[分析题目关键信息]

### 第二步：逐项分析
**A. [ ]**
```
[分析过程]
```

**B. [ ]**
```
[分析过程]
```

### 第三步：确认答案
[总结判断依据]
"""

        if "## 易错点分析" not in body:
            body += """
## 易错点分析

### 易错点1：[常见误解]
错误理解：[错误想法]
正确理解：[正确理解]

### 易错点2：[易混淆概念]
| 概念A | 概念B | 区别 |
|-------|-------|------|
| ... | ... | ... |
"""

        # 写回
        new_content = f"---\n{new_fm}\n---\n{body}"
        filepath.write_text(new_content, encoding='utf-8')

        print(f"  [完成] {filepath.name}")
        return "success"

    except Exception as e:
        print(f"  [错误] {filepath.name}: {e}")
        return "error"

def main():
    print("="*60)
    print("批量优化操作系统选择题")
    print("="*60)

    base = Path(BASE_PATH)
    files = list(base.rglob("*.md"))

    print(f"\n找到 {len(files)} 个文件\n")

    # 按目录分组
    dirs = {}
    for f in files:
        d = f.parent.name
        dirs.setdefault(d, []).append(f)

    success = skip = error = 0

    for dirname in sorted(dirs.keys()):
        print(f"\n[{dirname}] {len(dirs[dirname])} 个文件")
        print("-"*60)

        for f in sorted(dirs[dirname]):
            result = process_file(f)
            if result == "success":
                success += 1
            elif result == "skip":
                skip += 1
            elif result == "error":
                error += 1

    print("\n" + "="*60)
    print("处理统计")
    print("="*60)
    print(f"总计: {len(files)}")
    print(f"成功: {success}")
    print(f"跳过: {skip}")
    print(f"错误: {error}")
    print("="*60)

if __name__ == "__main__":
    main()
