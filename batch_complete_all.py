#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
批量补充408题库详细内容
使用Claude API批量生成高质量解析
"""

import os
import re
import json
import time
from pathlib import Path
from anthropic import Anthropic

# 配置
VAULT_PATH = Path(r"C:\Users\86172\Documents\Obsidian Vault\408真题知识库")
题库_PATH = VAULT_PATH / "408题库" / "02-按知识点-选择题"
参考示例 = VAULT_PATH / "408题库" / "02-按知识点-选择题" / "数据结构" / "01-线性表" / "2023年第01题-顺序表.md"

# 初始化API
client = Anthropic(api_key=os.environ.get("ANTHROPIC_API_KEY"))

def 读取示例格式():
    """读取参考示例"""
    with open(参考示例, 'r', encoding='utf-8') as f:
        return f.read()

def 检查是否已完成(file_path):
    """检查题目是否已有详细内容"""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
            # 检查是否有解题思路部分
            if "## 解题思路" in content or "### 第一步：" in content:
                # 检查是否是空框架
                if "[分析过程]" in content or "[易错点]" in content:
                    return False
                return True
    except:
        pass
    return False

def 提取题目信息(file_path):
    """从文件中提取题目内容"""
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # 提取metadata
    metadata_match = re.search(r'---\n(.*?)\n---', content, re.DOTALL)
    metadata = metadata_match.group(1) if metadata_match else ""

    # 提取题干
    题干_match = re.search(r'\*\*题干\*\*\n\n(.*?)\n\n(?:\*\*答案\*\*|A\.)', content, re.DOTALL)
    题干 = 题干_match.group(1).strip() if 题干_match else ""

    # 提取选项
    选项_pattern = r'([A-D])\.\s*([^\n]+)'
    选项 = re.findall(选项_pattern, content)

    # 提取答案
    答案_match = re.search(r'\*\*答案\*\*[：:]\s*([A-D])', content)
    答案 = 答案_match.group(1) if 答案_match else ""

    return {
        'metadata': metadata,
        '题干': 题干,
        '选项': 选项,
        '答案': 答案,
        '原文': content
    }

def 生成详细内容(题目信息, 参考格式):
    """使用Claude API生成详细内容"""

    提示词 = f"""你是408考研真题解析专家。请为以下题目生成详细的解析内容。

**参考格式**（必须严格遵循）：
{参考格式[参考格式.find("## 解题思路"):参考格式.find("---")]}

**题目信息**：
题干：{题目信息['题干']}

选项：
{chr(10).join([f"{opt[0]}. {opt[1]}" for opt in 题目信息['选项']])}

答案：{题目信息['答案']}

**要求**：
1. 必须包含"## 解题思路（逐项分析法）"章节，包含四个步骤
2. 必须逐项分析所有选项，用✅/❌标记
3. 必须包含"## 易错点分析"，至少2个陷阱
4. 必须包含"## 知识点对比"表格
5. 不要使用占位符如[分析过程]、[易错点]
6. 输出纯markdown格式，不要有```markdown包裹

直接输出解析内容："""

    try:
        response = client.messages.create(
            model="claude-sonnet-4-20250514",
            max_tokens=4000,
            messages=[{"role": "user", "content": 提示词}]
        )
        return response.content[0].text
    except Exception as e:
        print(f"API调用失败: {e}")
        return None

def 补充题目(file_path, 参考格式):
    """补充单个题目"""
    print(f"处理: {file_path.name}")

    # 检查是否已完成
    if 检查是否已完成(file_path):
        print(f"  ✓ 已完成，跳过")
        return True

    # 提取题目信息
    题目信息 = 提取题目信息(file_path)
    if not 题目信息['题干']:
        print(f"  ✗ 无法提取题目信息")
        return False

    # 生成详细内容
    详细内容 = 生成详细内容(题目信息, 参考格式)
    if not 详细内容:
        return False

    # 追加到文件
    with open(file_path, 'a', encoding='utf-8') as f:
        f.write(f"\n\n{详细内容}\n")

    print(f"  ✓ 已补充")
    return True

def 批量处理(科目, 最大数量=None):
    """批量处理某个科目"""
    科目路径 =题库_PATH / 科目

    if not 科目路径.exists():
        print(f"科目不存在: {科目}")
        return

    # 读取参考格式
    参考格式 = 读取示例格式()

    # 查找所有md文件
    所有题目 = list(科目路径.rglob("*.md"))
    待处理 = [f for f in 所有题目 if not 检查是否已完成(f)]

    print(f"\n{'='*60}")
    print(f"科目: {科目}")
    print(f"总题目: {len(所有题目)}")
    print(f"待处理: {len(待处理)}")
    print(f"{'='*60}\n")

    if 最大数量:
        待处理 = 待处理[:最大数量]

    成功 = 0
    失败 = 0

    for i, file_path in enumerate(待处理, 1):
        print(f"[{i}/{len(待处理)}] ", end="")

        if 补充题目(file_path, 参考格式):
            成功 += 1
        else:
            失败 += 1

        # API限流
        if i % 5 == 0:
            print("  暂停3秒...")
            time.sleep(3)

    print(f"\n完成: 成功{成功}, 失败{失败}")

def 统计进度():
    """统计各科目完成进度"""
    科目列表 = ["操作系统", "数据结构", "计算机组成原理", "计算机网络"]

    print("\n" + "="*60)
    print("完成进度统计")
    print("="*60)

    总数 = 0
    已完成 = 0

    for 科目 in 科目列表:
        科目路径 =题库_PATH / 科目
        所有题目 = list(科目路径.rglob("*.md"))
        完成数 = sum(1 for f in 所有题目 if 检查是否已完成(f))

        总数 += len(所有题目)
        已完成 += 完成数

        百分比 = 完成数 * 100 / len(所有题目) if 所有题目 else 0
        print(f"{科目:12s}: {完成数:3d}/{len(所有题目):3d} ({百分比:.1f}%)")

    总百分比 = 已完成 * 100 / 总数 if 总数 else 0
    print(f"{'-'*60}")
    print(f"{'总计':12s}: {已完成:3d}/{总数:3d} ({总百分比:.1f}%)")
    print("="*60 + "\n")

if __name__ == "__main__":
    import sys

    if len(sys.argv) < 2:
        print("用法:")
        print("  python batch_complete_all.py 统计")
        print("  python batch_complete_all.py 数据结构 [数量]")
        print("  python batch_complete_all.py 计算机组成原理 [数量]")
        print("  python batch_complete_all.py 计算机网络 [数量]")
        print("  python batch_complete_all.py 全部")
        sys.exit(1)

    命令 = sys.argv[1]

    if 命令 == "统计":
        统计进度()
    elif 命令 == "全部":
        for 科目 in ["数据结构", "计算机组成原理", "计算机网络"]:
            批量处理(科目)
    elif 命令 in ["操作系统", "数据结构", "计算机组成原理", "计算机网络"]:
        最大数量 = int(sys.argv[2]) if len(sys.argv) > 2 else None
        批量处理(命令, 最大数量)
    else:
        print(f"未知命令: {命令}")
