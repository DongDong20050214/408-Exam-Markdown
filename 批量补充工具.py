#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
408真题知识库批量补充工具
自动为所有未完成的题目添加标准解题思路和易错点分析
"""

import os
import sys

SOLUTION_TEMPLATE = """

## 解题思路

### 第一步：理解题目核心
分析题目考查的核心知识点

### 第二步：逐项分析
**A选项 ✅/❌**
```
分析过程
结论：
```

**B选项 ✅/❌**
```
分析过程
结论：
```

**C选项 ✅/❌**
```
分析过程
结论：
```

**D选项 ✅/❌**
```
分析过程
结论：
```

### 第三步：确认答案
根据分析确定答案

## 易错点分析

### 易错点1：主要误区
❌ 错误理解：
✅ 正确理解：

### 易错点2：概念混淆
| 概念A | 概念B | 区别 |
|-------|-------|------|
| 内容 | 内容 | 说明 |
"""

def has_solution(content):
    """检查文件是否已有完整解题思路"""
    return ("## 解题思路" in content and
            "### 第一步" in content and
            "## 易错点分析" in content and
            "易错点1" in content)

def process_file(filepath):
    """处理单个文件"""
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()

        # 跳过已完成的文件
        if has_solution(content):
            return "已完成"

        # 跳过特殊文件
        filename = os.path.basename(filepath)
        if filename.startswith('分类') or filename == 'README.md':
            return "跳过"

        # 添加模板
        if not content.rstrip().endswith('---'):
            content = content.rstrip() + '\n'
        content += SOLUTION_TEMPLATE

        # 写回文件
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)

        return "已处理"

    except Exception as e:
        return f"错误: {e}"

def main():
    base_dir = "408题库/02-按知识点-选择题"

    if not os.path.exists(base_dir):
        print(f"错误：目录不存在 {base_dir}")
        print("请确保在 408真题知识库 目录下运行此脚本")
        sys.exit(1)

    stats = {"已完成": 0, "已处理": 0, "跳过": 0, "错误": 0}
    errors = []

    # 遍历所有md文件
    for root, dirs, files in os.walk(base_dir):
        for filename in files:
            if not filename.endswith('.md'):
                continue

            filepath = os.path.join(root, filename)
            result = process_file(filepath)

            stats[result.split(':')[0]] = stats.get(result.split(':')[0], 0) + 1

            if result.startswith("错误"):
                errors.append(f"{filepath}: {result}")

    # 输出统计
    print("=" * 60)
    print("批量补充完成")
    print("=" * 60)
    print(f"已完成（跳过）: {stats['已完成']}")
    print(f"新增补充: {stats['已处理']}")
    print(f"跳过特殊文件: {stats['跳过']}")
    print(f"处理错误: {stats['错误']}")
    print("=" * 60)

    if errors:
        print("\n错误详情：")
        for err in errors[:10]:  # 只显示前10个错误
            print(f"  {err}")
        if len(errors) > 10:
            print(f"  ... 还有 {len(errors)-10} 个错误")

    print("\n提示：此工具添加了标准模板，后续可手动完善具体内容")

if __name__ == '__main__':
    main()
