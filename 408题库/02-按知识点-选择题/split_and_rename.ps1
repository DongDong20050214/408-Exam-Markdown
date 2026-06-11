# 408题目拆分与重命名脚本
# 功能：
# 1. 拆分多题文件（按 ## YYYY年第XX题 分割）
# 2. 重命名单题文件（添加年份题号前缀）
# 3. 记录所有变更，便于后续修复链接

$ErrorActionPreference = "Stop"
$logFile = "split_rename_log.json"
$changeLog = @()

# 递归处理所有md文件
$files = Get-ChildItem -Recurse -Filter "*.md" | Where-Object {
    $_.Name -notmatch "^(分类|process|README|split_rename)"
}

Write-Host "找到 $($files.Count) 个文件待处理"

foreach ($file in $files) {
    try {
        $content = Get-Content -Path $file.FullName -Raw -Encoding UTF8
        $relativePath = $file.FullName.Replace($PWD.Path + "\", "")

        # 检查是否已经是标准格式（文件名以年份开头）
        if ($file.Name -match '^\d{4}年第\d+题') {
            Write-Host "✓ 跳过（已标准格式）: $relativePath" -ForegroundColor Green
            continue
        }

        # 查找所有题目标记（## YYYY年第XX题）
        $matches = [regex]::Matches($content, '(?m)^## (\d{4})年第(\d+)题')

        if ($matches.Count -eq 0) {
            Write-Host "⚠ 未找到题目标记: $relativePath" -ForegroundColor Yellow
            continue
        }

        if ($matches.Count -eq 1) {
            # 单题文件，直接重命名
            $year = $matches[0].Groups[1].Value
            $num = $matches[0].Groups[2].Value
            $knowledgePoint = $file.BaseName
            $newName = "${year}年第${num}题-${knowledgePoint}.md"
            $newPath = Join-Path $file.Directory.FullName $newName

            if (Test-Path $newPath) {
                Write-Host "✗ 目标文件已存在: $newName" -ForegroundColor Red
                continue
            }

            Move-Item -Path $file.FullName -Destination $newPath
            Write-Host "→ 重命名: $($file.Name) => $newName" -ForegroundColor Cyan

            $changeLog += @{
                action = "rename"
                oldPath = $relativePath
                newPath = $relativePath.Replace($file.Name, $newName)
                oldName = $file.Name
                newName = $newName
            }
        } else {
            # 多题文件，需要拆分
            Write-Host "⊕ 拆分 ($($matches.Count) 道题): $relativePath" -ForegroundColor Magenta

            # 提取frontmatter
            $frontmatterMatch = [regex]::Match($content, '(?s)^---\r?\n(.*?)\r?\n---')
            $frontmatter = if ($frontmatterMatch.Success) { $frontmatterMatch.Value } else { "" }

            # 按题目分割
            for ($i = 0; $i -lt $matches.Count; $i++) {
                $startPos = $matches[$i].Index
                $endPos = if ($i -lt $matches.Count - 1) {
                    $matches[$i + 1].Index
                } else {
                    $content.Length
                }

                $year = $matches[$i].Groups[1].Value
                $num = $matches[$i].Groups[2].Value
                $knowledgePoint = $file.BaseName

                # 提取这道题的内容
                $questionContent = $content.Substring($startPos, $endPos - $startPos).TrimEnd()

                # 构建新文件内容
                $newContent = if ($frontmatter) {
                    # 更新frontmatter中的title
                    $updatedFrontmatter = $frontmatter -replace 'title:.*', "title: ${year}年第${num}题"
                    "$updatedFrontmatter`n`n$questionContent`n"
                } else {
                    "---`ntitle: ${year}年第${num}题`ntopic: 未分类`ntags:`n  - 选择题`n---`n`n$questionContent`n"
                }

                # 生成新文件名
                $newName = "${year}年第${num}题-${knowledgePoint}.md"
                $newPath = Join-Path $file.Directory.FullName $newName

                if (Test-Path $newPath) {
                    Write-Host "  ✗ 目标文件已存在: $newName" -ForegroundColor Red
                    continue
                }

                # 写入新文件
                [System.IO.File]::WriteAllText($newPath, $newContent, [System.Text.UTF8Encoding]::new($false))
                Write-Host "  + 创建: $newName" -ForegroundColor Green

                $changeLog += @{
                    action = "split"
                    sourcePath = $relativePath
                    newPath = $relativePath.Replace($file.Name, $newName)
                    oldName = $file.Name
                    newName = $newName
                    year = $year
                    num = $num
                }
            }

            # 删除原文件
            Remove-Item -Path $file.FullName -Force
            Write-Host "  - 删除原文件: $($file.Name)" -ForegroundColor DarkGray

            $changeLog += @{
                action = "delete"
                path = $relativePath
                name = $file.Name
            }
        }

    } catch {
        Write-Host "✗ 处理失败: $relativePath - $_" -ForegroundColor Red
    }
}

# 保存变更日志
$changeLog | ConvertTo-Json -Depth 10 | Out-File -FilePath $logFile -Encoding UTF8
Write-Host "`n✓ 处理完成！变更日志已保存到: $logFile" -ForegroundColor Green
Write-Host "总共处理了 $($changeLog.Count) 个变更操作"
