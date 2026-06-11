# 批量处理数据结构题目分类脚本

$baseDir = "C:\Users\86172\Documents\Obsidian Vault\408题库\02-按知识点-选择题"
$sourceDirs = @(
    "$baseDir\数据结构\_补充题目",
    "$baseDir\_补充完整"
)

# 章节映射到目标文件夹
$chapterMap = @{
    "栈队列" = "$baseDir\数据结构\02-栈队列串"
    "栈队列串" = "$baseDir\数据结构\02-栈队列串"
    "树" = "$baseDir\数据结构\03-树"
    "图" = "$baseDir\数据结构\04-图"
    "算法基础" = "$baseDir\数据结构\00-算法基础"
    "线性表" = "$baseDir\数据结构\01-线性表"
    "查找排序" = "$baseDir\数据结构\05-查找排序"
    "查找" = "$baseDir\数据结构\05-查找排序"
    "排序" = "$baseDir\数据结构\05-查找排序"
}

# 函数：提取YAML元数据
function Get-YAMLMetadata {
    param($filePath)

    $content = Get-Content $filePath -Raw -Encoding UTF8

    # 检查是否有YAML front matter
    if ($content -match '(?s)^---\s*\n(.*?)\n---') {
        $yamlContent = $matches[1]

        # 提取chapter
        $chapter = $null
        if ($yamlContent -match 'chapter:\s*(.+)') {
            $chapter = $matches[1].Trim()
        }

        # 提取knowledge_point
        $knowledgePoint = $null
        if ($yamlContent -match 'knowledge_point:\s*(.+)') {
            $knowledgePoint = $matches[1].Trim()
        }

        # 提取title来获取年份和题号
        $title = $null
        if ($yamlContent -match 'title:\s*(.+)') {
            $title = $matches[1].Trim()
        }

        return @{
            chapter = $chapter
            knowledge_point = $knowledgePoint
            title = $title
        }
    }

    return $null
}

# 函数：从文件名或内容提取年份和题号
function Get-YearAndNumber {
    param($fileName, $metadata)

    # 先尝试从metadata的title中提取
    if ($metadata -and $metadata.title) {
        if ($metadata.title -match '(\d{4})年第(\d+)题') {
            return @{
                year = $matches[1]
                number = $matches[2].PadLeft(2, '0')
            }
        }
        if ($metadata.title -match '(\d{4})年第(\d+)题') {
            return @{
                year = $matches[1]
                number = $matches[2].PadLeft(2, '0')
            }
        }
    }

    # 从文件名提取
    if ($fileName -match '(\d{4})-(\d+)\.md') {
        return @{
            year = $matches[1]
            number = $matches[2].PadLeft(2, '0')
        }
    }

    if ($fileName -match '(\d{4})年第(\d+)题') {
        return @{
            year = $matches[1]
            number = $matches[2].PadLeft(2, '0')
        }
    }

    return $null
}

$processedCount = 0
$skippedCount = 0
$errorCount = 0
$log = @()

foreach ($sourceDir in $sourceDirs) {
    if (-not (Test-Path $sourceDir)) {
        Write-Host "源目录不存在: $sourceDir" -ForegroundColor Yellow
        continue
    }

    $files = Get-ChildItem -Path $sourceDir -Filter "*.md" -File

    foreach ($file in $files) {
        try {
            Write-Host "处理: $($file.Name)" -ForegroundColor Cyan

            # 跳过README
            if ($file.Name -eq "README.md") {
                Write-Host "  跳过README文件" -ForegroundColor Yellow
                $skippedCount++
                continue
            }

            # 读取YAML元数据
            $metadata = Get-YAMLMetadata -filePath $file.FullName

            if (-not $metadata) {
                Write-Host "  无法提取YAML元数据，跳过" -ForegroundColor Yellow
                $log += "跳过(无YAML): $($file.Name)"
                $skippedCount++
                continue
            }

            # 检查是否是数据结构题目
            if (-not $metadata.chapter) {
                Write-Host "  无chapter字段，跳过" -ForegroundColor Yellow
                $log += "跳过(无chapter): $($file.Name)"
                $skippedCount++
                continue
            }

            # 查找目标文件夹
            $targetDir = $null
            foreach ($key in $chapterMap.Keys) {
                if ($metadata.chapter -like "*$key*") {
                    $targetDir = $chapterMap[$key]
                    break
                }
            }

            if (-not $targetDir) {
                Write-Host "  未找到匹配的目标文件夹 (chapter: $($metadata.chapter))，跳过" -ForegroundColor Yellow
                $log += "跳过(未匹配): $($file.Name) - chapter: $($metadata.chapter)"
                $skippedCount++
                continue
            }

            # 确保目标文件夹存在
            if (-not (Test-Path $targetDir)) {
                New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
            }

            # 提取年份和题号
            $yearInfo = Get-YearAndNumber -fileName $file.Name -metadata $metadata

            if (-not $yearInfo) {
                Write-Host "  无法提取年份和题号，跳过" -ForegroundColor Yellow
                $log += "跳过(无年份题号): $($file.Name)"
                $skippedCount++
                continue
            }

            # 生成新文件名
            $knowledgePoint = if ($metadata.knowledge_point) { $metadata.knowledge_point } else { "未分类" }
            $newFileName = "$($yearInfo.year)年第$($yearInfo.number)题-$knowledgePoint.md"
            $targetPath = Join-Path $targetDir $newFileName

            # 检查目标文件是否已存在
            if (Test-Path $targetPath) {
                Write-Host "  目标文件已存在: $newFileName" -ForegroundColor Yellow
                $log += "跳过(已存在): $($file.Name) -> $newFileName"
                $skippedCount++
                continue
            }

            # 移动文件
            Move-Item -Path $file.FullName -Destination $targetPath -Force
            Write-Host "  已移动到: $targetPath" -ForegroundColor Green
            $log += "成功: $($file.Name) -> $newFileName (目标: $targetDir)"
            $processedCount++

        } catch {
            Write-Host "  处理失败: $($_.Exception.Message)" -ForegroundColor Red
            $log += "错误: $($file.Name) - $($_.Exception.Message)"
            $errorCount++
        }
    }
}

# 输出统计信息
Write-Host "`n" -NoNewline
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "处理完成！" -ForegroundColor Green
Write-Host "成功处理: $processedCount 个文件" -ForegroundColor Green
Write-Host "跳过: $skippedCount 个文件" -ForegroundColor Yellow
Write-Host "错误: $errorCount 个文件" -ForegroundColor Red
Write-Host "========================================" -ForegroundColor Cyan

# 保存日志
$logPath = Join-Path $baseDir "process_log.txt"
$log | Out-File -FilePath $logPath -Encoding UTF8
Write-Host "`n日志已保存到: $logPath" -ForegroundColor Cyan

# 检查并删除空文件夹
Write-Host "`n检查空文件夹..." -ForegroundColor Cyan
foreach ($sourceDir in $sourceDirs) {
    if (Test-Path $sourceDir) {
        $items = Get-ChildItem -Path $sourceDir
        if ($items.Count -eq 0) {
            Remove-Item -Path $sourceDir -Force
            Write-Host "已删除空文件夹: $sourceDir" -ForegroundColor Green
        } else {
            Write-Host "文件夹非空，保留: $sourceDir (剩余 $($items.Count) 个文件)" -ForegroundColor Yellow
        }
    }
}
