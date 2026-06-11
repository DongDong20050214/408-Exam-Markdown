# -*- coding: utf-8 -*-
"""
批量优化操作系统选择题
按照AI优化标准模板优化文件
"""

import os
import re
from pathlib import Path
from datetime import datetime

# 基础路径
BASE_PATH = r"C:\Users\86172\Documents\Obsidian Vault\408真题知识库\408题库\02-按知识点-选择题\操作系统"

# 知识点考频映射（基于历年真题统计）
EXAM_FREQUENCY_MAP = {
    # 概述部分
    "系统调用": {"frequency": "高频", "count": 10},
    "中断": {"frequency": "高频", "count": 15},
    "用户态": {"frequency": "高频", "count": 12},
    "内核态": {"frequency": "高频", "count": 12},
    "特权指令": {"frequency": "高频", "count": 8},
    "批处理": {"frequency": "中频", "count": 5},
    "多任务": {"frequency": "中频", "count": 6},

    # 进程管理
    "进程": {"frequency": "高频", "count": 20},
    "线程": {"frequency": "高频", "count": 15},
    "调度": {"frequency": "高频", "count": 18},
    "死锁": {"frequency": "高频", "count": 16},
    "信号量": {"frequency": "高频", "count": 12},
    "互斥": {"frequency": "高频", "count": 14},
    "同步": {"frequency": "高频", "count": 12},
    "银行家算法": {"frequency": "高频", "count": 8},
    "PV操作": {"frequency": "高频", "count": 10},
    "管程": {"frequency": "中频", "count": 6},

    # 内存管理
    "页表": {"frequency": "高频", "count": 15},
    "页面置换": {"frequency": "高频", "count": 14},
    "LRU": {"frequency": "高频", "count": 10},
    "虚拟内存": {"frequency": "高频", "count": 12},
    "分页": {"frequency": "高频", "count": 15},
    "分段": {"frequency": "中频", "count": 7},
    "TLB": {"frequency": "中频", "count": 5},
    "缺页": {"frequency": "高频", "count": 10},
    "抖动": {"frequency": "中频", "count": 4},

    # 文件管理
    "文件": {"frequency": "高频", "count": 12},
    "索引": {"frequency": "高频", "count": 10},
    "磁盘": {"frequency": "高频", "count": 14},
    "位图": {"frequency": "中频", "count": 6},
    "链接": {"frequency": "中频", "count": 5},

    # IO管理
    "IO": {"frequency": "中频", "count": 7},
    "DMA": {"frequency": "中频", "count": 5},
    "缓冲": {"frequency": "中频", "count": 6},
    "SPOOL": {"frequency": "低频", "count": 3},
}

def extract_year_from_filename(filename):
    """从文件名提取年份"""
    match = re.match(r'(\d{4})年', filename)
    if match:
        return int(match.group(1))
    return None

def extract_question_number(filename):
    """从文件名提取题号"""
    match = re.search(r'第(\d+)题', filename)
    if match:
        return int(match.group(1))
    return None

def determine_difficulty(content, knowledge_point):
    """基于内容判断难度"""
    # 简单规则：根据关键词判断
    if any(kw in content for kw in ["计算", "推导", "证明", "银行家", "页面置换算法"]):
        return 4
    elif any(kw in content for kw in ["分析", "比较", "区别"]):
        return 3
    elif any(kw in content for kw in ["概念", "定义", "特点"]):
        return 2
    else:
        return 2  # 默认中等

def get_exam_frequency(knowledge_point):
    """获取考频信息"""
    for key, value in EXAM_FREQUENCY_MAP.items():
        if key in knowledge_point:
            return value["frequency"], value["count"]
    return "中频", 5  # 默认值

def check_has_image(content):
    """检查是否包含图片"""
    return bool(re.search(r'!\[.*?\]\(.*?\)', content))

def parse_frontmatter(content):
    """解析frontmatter"""
    match = re.match(r'^---\n(.*?)\n---\n', content, re.DOTALL)
    if match:
        return match.group(1), match.end()
    return None, 0

def build_enhanced_frontmatter(original_fm, year, question_num, difficulty,
                                 exam_freq, exam_count, has_image):
    """构建增强的frontmatter"""
    # 检查是否已有AI优化字段
    if "# ===== 以下为AI优化新增字段 =====" in original_fm:
        return original_fm  # 已优化，跳过

    question_id = f"{year}-OS-{question_num:02d}"

    enhanced = original_fm.rstrip() + "\n\n"
    enhanced += "# ===== 以下为AI优化新增字段 =====\n"
    enhanced += f"year: {year}\n"
    enhanced += f'question_id: "{question_id}"\n'
    enhanced += f"difficulty: {difficulty}\n"
    enhanced += f'exam_frequency: "{exam_freq}"\n'
    enhanced += f"exam_count: {exam_count}\n"
    enhanced += f"has_image: {str(has_image).lower()}\n"
    enhanced += "related_questions: []\n"
    enhanced += "related_knowledge: []\n"

    return enhanced

def has_section(content, section_name):
    """检查是否已有某个章节"""
    return f"## {section_name}" in content

def add_basic_analysis_sections(content, knowledge_point, year):
    """添加基础的解题思路和易错点分析"""
    if has_section(content, "解题思路") and has_section(content, "易错点分析"):
        return content  # 已有完整分析

    additions = "\n"

    if not has_section(content, "解题思路"):
        additions += "## 解题思路\n\n"
        additions += "### 第一步：明确题目要求\n"
        additions += "[分析题目关键信息]\n\n"
        additions += "### 第二步：逐项分析\n"
        additions += "**A. [ ]**\n"
        additions += "```\n[分析过程]\n```\n\n"
        additions += "**B. [ ]**\n"
        additions += "```\n[分析过程]\n```\n\n"
        additions += "### 第三步：确认答案\n"
        additions += "[总结判断依据]\n\n"

    if not has_section(content, "易错点分析"):
        additions += "## 易错点分析\n\n"
        additions += "### 易错点1：[常见误解]\n"
        additions += "❌ **错误理解**：[错误想法]\n"
        additions += "✅ **正确理解**：[正确理解]\n\n"
        additions += "### 易错点2：[易混淆概念]\n"
        additions += "| 概念A | 概念B | 区别 |\n"
        additions += "|-------|-------|------|\n"
        additions += "| ... | ... | ... |\n\n"

    return content + additions

def process_file(filepath):
    """处理单个文件"""
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()

        # 解析frontmatter
        fm_content, fm_end = parse_frontmatter(content)
        if not fm_content:
            print(f"  ⚠️  无frontmatter: {filepath.name}")
            return False

        # 检查是否已优化
        if "# ===== 以下为AI优化新增字段 =====" in fm_content:
            print(f"  [OK] 已优化: {filepath.name}")
            return True

        # 提取信息
        year = extract_year_from_filename(filepath.name)
        question_num = extract_question_number(filepath.name)

        if not year or not question_num:
            print(f"  [警告] 无法提取年份/题号: {filepath.name}")
            return False

        # 提取知识点
        kp_match = re.search(r'knowledge_point:\s*(.+)', fm_content)
        knowledge_point = kp_match.group(1).strip() if kp_match else ""

        # 判断各项属性
        difficulty = determine_difficulty(content, knowledge_point)
        exam_freq, exam_count = get_exam_frequency(knowledge_point)
        has_image = check_has_image(content)

        # 构建新的frontmatter
        new_fm = build_enhanced_frontmatter(fm_content, year, question_num,
                                             difficulty, exam_freq, exam_count, has_image)

        # 替换frontmatter
        new_content = "---\n" + new_fm + "---\n" + content[fm_end:]

        # 添加分析章节（简化版）
        new_content = add_basic_analysis_sections(new_content, knowledge_point, year)

        # 写回文件
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(new_content)

        print(f"  ✅ 优化完成: {filepath.name}")
        return True

    except Exception as e:
        print(f"  ❌ 处理失败: {filepath.name} - {str(e)}")
        return False

def main():
    """主函数"""
    print("="*60)
    print("408操作系统选择题批量优化工具")
    print("="*60)

    base_path = Path(BASE_PATH)
    if not base_path.exists():
        print(f"[错误] 路径不存在: {BASE_PATH}")
        return

    # 收集所有md文件
    md_files = list(base_path.rglob("*.md"))
    total = len(md_files)

    print(f"\n[统计] 找到 {total} 个文件\n")

    # 按子目录分组处理
    subdirs = {}
    for f in md_files:
        subdir = f.parent.name
        if subdir not in subdirs:
            subdirs[subdir] = []
        subdirs[subdir].append(f)

    success_count = 0
    skip_count = 0
    fail_count = 0

    for subdir, files in sorted(subdirs.items()):
        print(f"\n[目录] 处理目录: {subdir} ({len(files)}个文件)")
        print("-" * 60)

        for filepath in sorted(files):
            result = process_file(filepath)
            if result is True:
                success_count += 1
            elif result is False:
                fail_count += 1

    # 输出统计
    print("\n" + "="*60)
    print("[完成] 处理完成统计")
    print("="*60)
    print(f"总文件数: {total}")
    print(f"[成功] 成功优化: {success_count}")
    print(f"[失败] 处理失败: {fail_count}")
    print(f"[跳过] 已优化文件: {total - success_count - fail_count}")
    print("="*60)

if __name__ == "__main__":
    main()
