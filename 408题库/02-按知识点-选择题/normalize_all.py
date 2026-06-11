#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import os
import re
from pathlib import Path

BASE_DIR = Path(r"C:\Users\86172\Documents\Obsidian Vault\408真题知识库\408题库\02-按知识点-选择题")

count = 0

def extract_year_from_filename(filename):
    """从文件名提取年份"""
    match = re.search(r'(\d{4})年', filename)
    return match.group(1) if match else ''

def extract_qid_from_filename(filename):
    """从文件名提取题号"""
    match = re.search(r'第(\d+)题', filename)
    if match:
        year = extract_year_from_filename(filename)
        return f"{year}-{match.group(1)}"
    return ''

def normalize_frontmatter(filepath):
    """标准化frontmatter"""
    global count

    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()

        if not content.strip():
            return

        # 提取第一个frontmatter块
        if not content.startswith('---'):
            return

        match = re.match(r'^---\n(.*?)\n---\n(.*)$', content, re.DOTALL)
        if not match:
            return

        fm_text = match.group(1)
        body = match.group(2)

        # 解析现有字段
        fields = {}
        for line in fm_text.split('\n'):
            if ':' in line and not line.strip().startswith('#'):
                key, val = line.split(':', 1)
                key = key.strip()
                val = val.strip().strip('"')
                if key:
                    fields[key] = val

        # 从文件路径提取学科和章节
        parts = filepath.parts
        idx = parts.index('02-按知识点-选择题')
        subject = parts[idx + 1] if idx + 1 < len(parts) else ''
        chapter_dir = parts[idx + 2] if idx + 2 < len(parts) else ''

        # 标准化学科名
        subject_map = {
            '数据结构': '数据结构',
            '计算机组成原理': '计算机组成原理',
            '操作系统': '操作系统',
            '计算机网络': '计算机网络'
        }
        subject = subject_map.get(subject, subject)

        # 提取year和question_id
        year = fields.get('year', extract_year_from_filename(filepath.name))
        qid = fields.get('question_id', extract_qid_from_filename(filepath.name))

        if not year or not qid:
            return

        # 标准化章节
        chapter = fields.get('chapter', chapter_dir.split('-', 1)[-1] if '-' in chapter_dir else chapter_dir)

        # 标准化知识点
        kp = fields.get('knowledge_point', fields.get('topic', '未分类'))
        if '/' in kp:
            kp = kp.split('/')[-1]

        # 标准化难度
        diff = fields.get('difficulty', '3')
        if '⭐' in str(diff):
            diff = str(diff).count('⭐')
        diff = str(diff).strip()

        # 标准化频率
        freq = fields.get('frequency', fields.get('exam_frequency', '中频'))
        freq = freq.strip('"').replace('exam_frequency', '中频')

        # 标准化考频
        exam_cnt = fields.get('exam_count', '5')

        # 构建tags
        tag2 = kp if kp != '未分类' else chapter
        tags_str = f'["{subject}", "{tag2}"]'

        # 构建标准frontmatter
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

        new_content = new_fm + '\n' + body

        if new_content != content:
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(new_content)
            count += 1
            if count % 50 == 0:
                print(count, flush=True)

    except Exception as e:
        print(f"Error {filepath}: {e}")

def main():
    for md_file in BASE_DIR.rglob("*.md"):
        if md_file.name == "分类完成报告.md":
            continue
        normalize_frontmatter(md_file)

    print(f"\n共处理 {count} 个文件")

if __name__ == "__main__":
    main()
