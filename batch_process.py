#!/usr/bin/env python3
import os
import re

# 标准解题模板
SOLUTION_TEMPLATE = """

## 解题思路

### 第一步：理解题目核心概念
根据题目类型分析核心考点

### 第二步：逐项分析
**选项分析**：对每个选项进行判断，用✅❌标记

### 第三步：确认答案
根据分析得出正确答案

## 易错点分析

### 易错点1：常见误区
❌ 错误理解：
✅ 正确理解：

### 易错点2：概念混淆
| 概念A | 概念B | 区别 |
|-------|-------|------|
| 内容 | 内容 | 说明 |
"""

def has_solution(content):
    """检查是否已有解题思路"""
    return "## 解题思路" in content and "### 第一步" in content

def process_file(filepath):
    """处理单个文件"""
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()

        if has_solution(content):
            return False  # 已完成

        # 在文件末尾添加解题模板
        if not content.endswith('\n'):
            content += '\n'
        content += SOLUTION_TEMPLATE

        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        return True  # 已处理
    except Exception as e:
        print(f"Error processing {filepath}: {e}")
        return False

def main():
    base_dir = "408真题知识库/408题库/02-按知识点-选择题"
    processed = 0
    skipped = 0

    for root, dirs, files in os.walk(base_dir):
        for file in files:
            if file.endswith('.md') and not file.startswith('分类'):
                filepath = os.path.join(root, file)
                if process_file(filepath):
                    processed += 1
                else:
                    skipped += 1

    print(f"处理完成：新增{processed}个，跳过{skipped}个")

if __name__ == '__main__':
    main()
