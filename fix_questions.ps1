$ErrorActionPreference = "Stop"
$baseDir = "C:\Users\86172\Documents\Obsidian Vault\408真题知识库\408题库\02-按知识点-选择题"

$stats = @{
    files_checked = 0
    files_modified = @()
    duplicates_found = @()
    issues_summary = @{
        incomplete_questions = 0
        image_path_errors = 0
        missing_images = 0
        metadata_errors = 0
        wiki_links_fixed = 0
    }
}

$contentMap = @{}

function Extract-QuestionNumber {
    param([string]$filename)
    if ($filename -match "(\d{4})年第(\d+)题") {
        return @{
            year = [int]$matches[1]
            number = [int]$matches[2]
        }
    }
    return $null
}

function Check-File {
    param(
        [string]$filePath,
        [string]$subject,
        [int]$minQuestionNumber
    )

    $filename = Split-Path $filePath -Leaf
    $qInfo = Extract-QuestionNumber $filename

    if (-not $qInfo -or $qInfo.number -lt $minQuestionNumber) {
        return
    }

    $stats.files_checked++
    $content = Get-Content $filePath -Raw -Encoding UTF8
    $originalContent = $content
    $issues = @()

    # 检查重复内容
    $contentHash = $content.GetHashCode()
    if ($contentMap.ContainsKey($contentHash)) {
        $stats.duplicates_found += @{
            files = @($contentMap[$contentHash], $filePath)
            same_content = $true
        }
    } else {
        $contentMap[$contentHash] = $filePath
    }

    # 1. 检查题干完整性（是否包含所有选项）
    if ($content -match "^##\s*题目" -and -not ($content -match "A\.|A、" -and $content -match "B\.|B、" -and $content -match "C\.|C、" -and $content -match "D\.|D、")) {
        $issues += "题干不完整"
        $stats.issues_summary.incomplete_questions++
    }

    # 2. 修复图片路径错误
    if ($content -match '\!\[([^\]]*)\]\(([^\)]+\.(?:png|jpeg|jpg|gif))\.md\)') {
        $content = $content -replace '(\!\[[^\]]*\]\([^\)]+\.(?:png|jpeg|jpg|gif))\.md\)', '$1)'
        $issues += "图片路径错误"
        $stats.issues_summary.image_path_errors++
    }

    # 3. 检查图片是否存在
    $imageMatches = [regex]::Matches($content, '\!\[([^\]]*)\]\(([^\)]+)\)')
    foreach ($match in $imageMatches) {
        $imgPath = $match.Groups[2].Value
        if ($imgPath -notmatch '^https?://') {
            $fullImgPath = Join-Path (Split-Path $filePath -Parent) $imgPath
            if (-not (Test-Path $fullImgPath)) {
                if ($content -notmatch "<!-- 图片缺失：$([regex]::Escape($imgPath)) -->") {
                    $content += "`n`n<!-- 图片缺失：$imgPath -->"
                    $issues += "图片缺失"
                    $stats.issues_summary.missing_images++
                }
            }
        }
    }

    # 4. 修复question_id格式
    $subjectCode = if ($subject -eq "操作系统") { "OS" } else { "CO" }
    $expectedQid = "$($qInfo.year)-$subjectCode-$($qInfo.number)"

    if ($content -match 'question_id:\s*(.+)') {
        $currentQid = $matches[1].Trim()
        if ($currentQid -ne $expectedQid) {
            $content = $content -replace "(question_id:\s*)(.+)", "`$1$expectedQid"
            $issues += "元数据question_id错误"
            $stats.issues_summary.metadata_errors++
        }
    }

    # 5. 转换Wiki链接为markdown链接
    $wikiLinkPattern = '\[\[([^\]]+)\]\]'
    if ($content -match $wikiLinkPattern) {
        $content = [regex]::Replace($content, $wikiLinkPattern, {
            param($m)
            $linkText = $m.Groups[1].Value
            if ($linkText -notmatch '\.' -and $linkText -notmatch '/') {
                "[$linkText]($linkText.md)"
            } elseif ($linkText -match '^([^/]+)$') {
                "[$linkText]($linkText)"
            } else {
                "[$linkText]($linkText)"
            }
        })
        $issues += "Wiki链接转换"
        $stats.issues_summary.wiki_links_fixed++
    }

    # 写入修改
    if ($content -ne $originalContent) {
        Set-Content -Path $filePath -Value $content -Encoding UTF8 -NoNewline
        $stats.files_modified += @{
            file = $filePath
            issues = $issues
        }
    }
}

# 处理操作系统
Write-Host "处理操作系统题目（题号>=46）..."
Get-ChildItem "$baseDir\操作系统" -Recurse -Filter "*.md" | ForEach-Object {
    Check-File -filePath $_.FullName -subject "操作系统" -minQuestionNumber 46
}

# 处理计算机组成原理
Write-Host "处理计算机组成原理题目（题号>=91）..."
Get-ChildItem "$baseDir\计算机组成原理" -Recurse -Filter "*.md" | ForEach-Object {
    Check-File -filePath $_.FullName -subject "计算机组成原理" -minQuestionNumber 91
}

# 输出JSON
$jsonOutput = $stats | ConvertTo-Json -Depth 10
Write-Host "`n=== 统计结果 ==="
Write-Host $jsonOutput
$jsonOutput | Out-File "C:\Users\86172\Documents\Obsidian Vault\408真题知识库\fix_report.json" -Encoding UTF8
