#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import os
import re
from pathlib import Path

BASE_DIR = Path(r"C:\Users\86172\Documents\Obsidian Vault\408真题知识库\408题库\02-按知识点-选择题")

# 知识点映射
SUBJECT_MAP = {
    "数据结构": "数据结构",
    "计算机组成原理": "计算机组成原理",
    "操作系统": "操作系统",
    "计算机网络": "计算机网络"
}

count = 0

def clean_frontmatter(content):
    """清理并标准化frontmatter"""
    # 提取第一个---...---块
    match = re.match(r'^---\n(.*?)\n---', content, re.DOTALL)
    if not match:
        return content

    fm_text = match.group(1)
    body = content[match.end():]

    # 解析现有字段
    fields = {}
    for line in fm_text.split('\n'):
        if ':' in line:
            key, val = line.split(':', 1)
            key = key.strip()
            val = val.strip().strip('"')
            if key and not key.startswith('#'):
                fields[key] = val

    # 提取year和question_id
    year = fields.get('year', '')
    qid = fields.get('question_id', '').strip('"')

    if not year or not qid:
        # 尝试从文件名提取
        return content

    # 构建标准frontmatter
    subject = fields.get('subject', fields.get('topic', '操作系统'))
    chapter = fields.get('chapter', '操作系统概述')
    kp = fields.get('knowledge_point', '未分类')
    diff = fields.get('difficulty', '3')
    freq = fields.get('frequency', fields.get('exam_frequency', '中频')).strip('"')
    exam_cnt = fields.get('exam_count', '5')

    # 清理tags
    tags_raw = fields.get('tags', '[]')
    if isinstance(tags_raw, str):
        if tags_raw.startswith('['):
            tags_raw = re.findall(r'"([^"]+)"', tags_raw)
        else:
            tags_raw = [tags_raw]
    tags = [t.split('/')[-1] for t in tags_raw if t and t.split('/')[-1] != subject][:1]
    tag2 = tags[0] if tags else kp
    tags_str = f'["{subject}", "{tag2}"]'

    new_fm = f"""---
year: {year}
question_id: "{qid}"
subject: {subject}
chapter: {chapter}
knowledge_point: {kp}
type: 选择题
difficulty: {diff}
frequency: {freq}
exam_count: {exam_cnt}
tags: {tags_str}
---"""

    # 清理body中的重复frontmatter
    body = re.sub(r'\n---\n.*?\n---\n', '\n', body, flags=re.DOTALL)

    return new_fm + body

def process_file(filepath):
    global count
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()

        if not content.startswith('---'):
            return

        # 检查是否有重复frontmatter或旧格式
        if content.count('---') > 2 or 'title:' in content[:500] or 'has_image:' in content:
            new_content = clean_frontmatter(content)
            if new_content != content:
                with open(filepath, 'w', encoding='utf-8') as f:
                    f.write(new_content)
                count += 1
                if count % 10 == 0:
                    print(f"{count}", flush=True)
    except Exception as e:
        print(f"Error {filepath}: {e}")

def main():
    for subject in ["操作系统", "数据结构", "计算机组成原理", "计算机网络"]:
        subject_dir = BASE_DIR / subject
        if not subject_dir.exists():
            continue

        for md_file in subject_dir.rglob("*.md"):
            if md_file.name == "分类完成报告.md":
                continue
            process_file(md_file)

    print(f"\n共处理 {count} 个文件")

if __name__ == "__main__":
    main()
