#!/usr/bin/env pwsh
# 修复未分类题目的知识点字段
# 基于文件路径和题目内容自动推断知识点

param(
    [switch]$Apply = $false
)

$repoRoot = Get-Location
$updated = 0
$errors = @()

# 知识点映射表：根据路径和题目名识别知识点
$knowledgePointMap = @{
    "进程调度" = "进程管理"
    "死锁" = "进程同步"
    "死锁处理" = "进程同步"
    "进程与线程" = "进程管理"
    "内存管理" = "虚拟存储器"
    "页面置换" = "页面置换算法"
    "存储保护" = "存储器"
    "缓存" = "缓存"
    "寄存器" = "寄存器"
}

Get-ChildItem -Path "408题库" -Recurse -Filter "*.md" | Where-Object {
    $content = Get-Content $_.FullName -Raw
    $content -match "knowledge_point: 未分类"
} | ForEach-Object {
    $file = $_
    $content = Get-Content $file.FullName -Raw
    $filename = $file.Name
    $dirPath = $file.DirectoryName

    # 尝试从文件名中提取知识点
    $newKnowledgePoint = $null

    foreach ($keyword in $knowledgePointMap.Keys) {
        if ($filename -match $keyword -or $content -match "## 考点分析.*\n$keyword") {
            $newKnowledgePoint = $knowledgePointMap[$keyword]
            break
        }
    }

    # 如果找不到，根据目录推断
    if (-not $newKnowledgePoint) {
        if ($dirPath -match "进程管理") {
            $newKnowledgePoint = "进程管理"
        } elseif ($dirPath -match "内存管理") {
            $newKnowledgePoint = "内存管理"
        } elseif ($dirPath -match "文件管理") {
            $newKnowledgePoint = "文件管理"
        } elseif ($dirPath -match "中断|异常") {
            $newKnowledgePoint = "中断系统"
        }
    }

    if ($newKnowledgePoint) {
        # 替换
        $newContent = $content -replace "knowledge_point: 未分类", "knowledge_point: $newKnowledgePoint"

        if ($Apply) {
            Set-Content -Path $file.FullName -Value $newContent -Encoding UTF8
            Write-Host "[~] $($file.Name) -> knowledge_point: $newKnowledgePoint"
        } else {
            Write-Host "[-] $($file.Name) -> knowledge_point: $newKnowledgePoint (预览)"
        }
        $updated++
    } else {
        $errors += $file.Name
        Write-Host "[!] $($file.Name) - 无法推断知识点"
    }
}

if ($Apply) {
    Write-Host ""
    Write-Host "修复完成：$updated 个题目已分类"
} else {
    Write-Host ""
    Write-Host "预览完成：$updated 个题目可分类，$($errors.Count) 个无法识别"
}

if ($errors.Count -gt 0) {
    Write-Host "无法识别的题目："
    $errors | ForEach-Object { Write-Host "  - $_" }
}
