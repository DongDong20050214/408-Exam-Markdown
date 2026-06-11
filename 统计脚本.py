import os
import re
from collections import defaultdict, Counter
from pathlib import Path

# 题库根目录（同时处理选择题和综合题）
base_dirs = [
    Path(r"C:\Users\86172\Documents\Obsidian Vault\408真题知识库\408题库\02-按知识点-选择题"),
    Path(r"C:\Users\86172\Documents\Obsidian Vault\408真题知识库\408题库\03-按知识点-综合题")
]

# 统计数据结构
knowledge_points = defaultdict(lambda: {"count": 0, "years": [], "difficulties": [], "subject": ""})
year_subject_count = defaultdict(lambda: defaultdict(int))
subject_difficulty = defaultdict(lambda: defaultdict(int))
all_questions = []

# 遍历所有md文件
for base_dir in base_dirs:
    for md_file in base_dir.rglob("*.md"):
        if md_file.name in ["README.md", "分类完成报告.md"]:
            continue

        try:
            content = md_file.read_text(encoding="utf-8")

            # 提取YAML frontmatter
            yaml_match = re.search(r'^---\s*\n(.*?)\n---', content, re.DOTALL | re.MULTILINE)
            if not yaml_match:
                continue

            yaml_content = yaml_match.group(1)

            # 提取字段
            year_match = re.search(r'year:\s*(\d+)', yaml_content)
            subject_match = re.search(r'subject:\s*(.+)', yaml_content)
            kp_match = re.search(r'knowledge_point:\s*(.+)', yaml_content)
            考点_match = re.search(r'考点:\s*\[([^\]]+)\]', yaml_content)
            difficulty_match = re.search(r'difficulty:\s*(\d+)', yaml_content)

            if not year_match:
                continue

            year = int(year_match.group(1))
            subject = subject_match.group(1).strip() if subject_match else ""
            difficulty = int(difficulty_match.group(1)) if difficulty_match else 0

            # 提取知识点
            kp_list = []
            if kp_match:
                kp_list.append(kp_match.group(1).strip())
            if 考点_match:
                kp_list.extend([k.strip() for k in 考点_match.group(1).split(",")])

            # 去重知识点
            kp_list = list(set(kp_list))

            # 记录题目信息
            question_info = {
                "file": str(md_file.relative_to(base_dir)),
                "year": year,
                "subject": subject,
                "knowledge_points": kp_list,
                "difficulty": difficulty
            }
            all_questions.append(question_info)

            # 统计年份-科目
            if subject:
                year_subject_count[year][subject] += 1

            # 统计科目-难度
            if subject and difficulty:
                subject_difficulty[subject][difficulty] += 1

            # 统计知识点
            for kp in kp_list:
                knowledge_points[kp]["count"] += 1
                knowledge_points[kp]["years"].append(year)
                knowledge_points[kp]["subject"] = subject
                if difficulty:
                    knowledge_points[kp]["difficulties"].append(difficulty)

        except Exception as e:
            print(f"处理文件 {md_file} 时出错: {e}")

# 生成报告1：各科目考频TOP20
output_dir = Path(r"C:\Users\86172\Documents\Obsidian Vault\408真题知识库\AI-统计分析")
output_dir.mkdir(exist_ok=True)

report1 = []
report1.append("# 408真题考频统计（2009-2024）\n\n")
report1.append(f"**统计时间**：2026-06-11\n\n")
report1.append(f"**数据来源**：408题库选择题+综合题\n\n")
report1.append(f"**统计题目数**：{len(all_questions)}题\n\n")

# 按科目分组统计
subject_kp = defaultdict(list)
for kp, data in knowledge_points.items():
    subject_kp[data["subject"]].append((kp, data["count"], data["years"]))

for subject in ["数据结构", "计算机组成原理", "操作系统", "计算机网络"]:
    if subject not in subject_kp:
        continue

    report1.append(f"## {subject}考频TOP20\n\n")
    report1.append("| 排名 | 知识点 | 考查次数 | 考查年份 |\n")
    report1.append("|------|--------|----------|----------|\n")

    kp_list = sorted(subject_kp[subject], key=lambda x: x[1], reverse=True)[:20]
    for i, (kp, count, years) in enumerate(kp_list, 1):
        years_str = ", ".join(map(str, sorted(years)))
        report1.append(f"| {i} | {kp} | {count} | {years_str} |\n")
    report1.append("\n")

(output_dir / "考频统计.md").write_text("".join(report1), encoding="utf-8")

# 生成报告2：年份趋势分析
report2 = []
report2.append("# 408真题年份趋势分析（2009-2024）\n\n")

# 各年份各科目题目数量
report2.append("## 各年份题目数量分布\n\n")
report2.append("| 年份 | 数据结构 | 计算机组成原理 | 操作系统 | 计算机网络 | 合计 |\n")
report2.append("|------|----------|----------------|----------|------------|------|\n")

for year in range(2009, 2025):
    ds = year_subject_count[year].get("数据结构", 0)
    ca = year_subject_count[year].get("计算机组成原理", 0)
    os = year_subject_count[year].get("操作系统", 0)
    cn = year_subject_count[year].get("计算机网络", 0)
    total = ds + ca + os + cn
    report2.append(f"| {year} | {ds} | {ca} | {os} | {cn} | {total} |\n")

report2.append("\n")

# 2020年后新增考点
report2.append("## 2020年后新增考点\n\n")
new_kps = {}
for kp, data in knowledge_points.items():
    if min(data["years"]) >= 2020:
        new_kps[kp] = (data["subject"], data["count"], min(data["years"]))

if new_kps:
    report2.append("| 知识点 | 科目 | 首次出现年份 | 考查次数 |\n")
    report2.append("|--------|------|--------------|----------|\n")
    for kp, (subj, count, first_year) in sorted(new_kps.items(), key=lambda x: x[1][2]):
        report2.append(f"| {kp} | {subj} | {first_year} | {count} |\n")
else:
    report2.append("无明显新增考点\n")

report2.append("\n")

# 近3年未考（淡化考点）
report2.append("## 淡化考点（近3年未考）\n\n")
faded_kps = {}
for kp, data in knowledge_points.items():
    if max(data["years"]) < 2022:
        faded_kps[kp] = (data["subject"], max(data["years"]), data["count"])

if faded_kps:
    report2.append("| 知识点 | 科目 | 最后考查年份 | 历史考查次数 |\n")
    report2.append("|--------|------|--------------|-------------|\n")
    for kp, (subj, last_year, count) in sorted(faded_kps.items(), key=lambda x: x[1][1], reverse=True):
        report2.append(f"| {kp} | {subj} | {last_year} | {count} |\n")
else:
    report2.append("所有考点近3年均有考查\n")

(output_dir / "年份趋势分析.md").write_text("".join(report2), encoding="utf-8")

# 生成报告3：难度分布
report3 = []
report3.append("# 408真题难度分布分析\n\n")

# 各科目难度分布
report3.append("## 各科目难度分布\n\n")
report3.append("| 科目 | 难度1 | 难度2 | 难度3 | 难度4 | 难度5 | 总计 |\n")
report3.append("|------|-------|-------|-------|-------|-------|------|\n")

for subject in ["数据结构", "计算机组成原理", "操作系统", "计算机网络"]:
    if subject not in subject_difficulty:
        continue
    d1 = subject_difficulty[subject].get(1, 0)
    d2 = subject_difficulty[subject].get(2, 0)
    d3 = subject_difficulty[subject].get(3, 0)
    d4 = subject_difficulty[subject].get(4, 0)
    d5 = subject_difficulty[subject].get(5, 0)
    total = d1 + d2 + d3 + d4 + d5
    report3.append(f"| {subject} | {d1} | {d2} | {d3} | {d4} | {d5} | {total} |\n")

report3.append("\n")

# 冷门考点（考1-2次）
report3.append("## 冷门考点清单（仅考1-2次）\n\n")

rare_kps = defaultdict(list)
for kp, data in knowledge_points.items():
    if data["count"] <= 2:
        rare_kps[data["subject"]].append((kp, data["count"], data["years"]))

for subject in ["数据结构", "计算机组成原理", "操作系统", "计算机网络"]:
    if subject not in rare_kps:
        continue

    report3.append(f"### {subject}\n\n")
    report3.append("| 知识点 | 考查次数 | 考查年份 |\n")
    report3.append("|--------|----------|----------|\n")

    for kp, count, years in sorted(rare_kps[subject], key=lambda x: x[1]):
        years_str = ", ".join(map(str, sorted(years)))
        report3.append(f"| {kp} | {count} | {years_str} |\n")
    report3.append("\n")

(output_dir / "难度分布.md").write_text("".join(report3), encoding="utf-8")

print(f"统计完成！共处理{len(all_questions)}道题目")
print(f"报告已生成至：{output_dir}")
