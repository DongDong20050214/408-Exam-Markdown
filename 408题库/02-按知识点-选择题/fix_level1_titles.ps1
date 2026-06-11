# 处理使用一级标题（# YYYY年第XX题）的文件
# 这些文件之前没被处理，现在补充处理

$ErrorActionPreference = "Stop"
$logFile = "fix_level1_log.json"
$changeLog = @()

$files = Get-ChildItem -Recurse -Filter "*.md" | Where-Object {
    $_.Name -notmatch "^(分类|process|README|split|fix_)"
}

Write-Host "开始处理一级标题文件..." -ForegroundColor Yellow

foreach ($file in $files) {
    try {
        # 跳过已标准格式
        if ($file.Name -match '^\d{4}年第\d+题') {
            continue
        }

        $content = Get-Content -Path $file.FullName -Raw -Encoding UTF8
        $relativePath = $file.FullName.Replace($PWD.Path + "\", "")

        # 只查找一级标题
        $match = [regex]::Match($content, '(?m)^# (\d{4})年第(\d+)题')

        if (!$match.Success) {
            continue
        }

        $year = $match.Groups[1].Value
        $num = $match.Groups[2].Value
        $knowledgePoint = $file.BaseName
        $newName = "${year}年第${num}题-${knowledgePoint}.md"
        $newPath = Join-Path $file.Directory.FullName $newName

        if (Test-Path $newPath) {
            Write-Host "✗ 目标文件已存在: $newName" -ForegroundColor Red
            continue
        }

        # 重命名
        Move-Item -Path $file.FullName -Destination $newPath
        Write-Host "→ 重命名: $($file.Name) => $newName" -ForegroundColor Cyan

        $changeLog += @{
            action = "rename"
            oldPath = $relativePath
            newPath = $relativePath.Replace($file.Name, $newName)
            oldName = $file.Name
            newName = $newName
            year = $year
            num = $num
        }

    } catch {
        Write-Host "✗ 处理失败: $relativePath - $_" -ForegroundColor Red
    }
}

# 保存日志
$changeLog | ConvertTo-Json -Depth 10 | Out-File -FilePath $logFile -Encoding UTF8
Write-Host "`n✓ 处理完成！变更日志已保存到: $logFile" -ForegroundColor Green
Write-Host "总共处理了 $($changeLog.Count) 个文件"
