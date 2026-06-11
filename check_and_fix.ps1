# 408题库文件检查和修复脚本
$ErrorActionPreference = 'Continue'

$result = @{
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

$questionContents = @{}
$baseDir = "C:\Users\86172\Documents\Obsidian Vault\408真题知识库\408题库\02-按知识点-选择题"

# 获取所有md文件
$coFiles = Get-ChildItem -Path "$baseDir\计算机组成原理" -Recurse -Filter "*.md"
$osFiles = Get-ChildItem -Path "$baseDir\操作系统" -Recurse -Filter "*.md"
$allFiles = $coFiles + $osFiles

foreach ($file in $allFiles) {
    $result.files_checked++
    $content = Get-Content -Path $file.FullName -Raw -Encoding UTF8
    $originalContent = $content
    $issues = @()
    $modified = $false

    # 1. 修复图片路径错误
    if ($content -match '\!\[([^\]]*)\]\(([^\)]+)\.(jpeg|png|jpg)\.md\)') {
        $content = $content -replace '\!\[([^\]]*)\]\(([^\)]+\.(jpeg|png|jpg))\.md\)', '![$1]($2)'
        $issues += "图片路径错误(.md后缀)"
        $result.issues_summary.image_path_errors++
        $modified = $true
    }

    # 2. 检查图片是否存在
    $imageMatches = [regex]::Matches($content, '\!\[([^\]]*)\]\(([^\)]+)\)')
    foreach ($match in $imageMatches) {
        $imgPath = $match.Groups[2].Value
        if (-not $imgPath.StartsWith('http')) {
            $fullImgPath = Join-Path (Split-Path $file.FullName) $imgPath
            if (-not (Test-Path $fullImgPath)) {
                if ($content -notmatch "<!-- 图片缺失：$($imgPath -replace '\\', '\\') -->") {
                    $content += "`n<!-- 图片缺失：$imgPath -->"
                    $issues += "图片缺失: $imgPath"
                    $result.issues_summary.missing_images++
                    $modified = $true
                }
            }
        }
    }

    # 3. 修复question_id格式
    if ($file.Name -match '^(\d{4})年第(\d+)题') {
        $year = $Matches[1]
        $num = $Matches[2]
        $subject = if ($file.FullName -match '\\计算机组成原理\\') { 'CO' } else { 'OS' }
        $expectedId = "$year-$subject-$num"

        if ($content -match 'question_id:\s*(.+?)(\r?\n|$)') {
            $currentId = $Matches[1].Trim()
            if ($currentId -ne $expectedId) {
                $content = $content -replace "(question_id:\s*)(.+?)(\r?\n)", "`$1$expectedId`$3"
                $issues += "question_id格式错误 ($currentId → $expectedId)"
                $result.issues_summary.metadata_errors++
                $modified = $true
            }
        }
    }

    # 4. 修复Wiki链接
    $wikiPattern = '\[\[([^\|\]]+)\|([^\]]+)\]\]'
    if ($content -match $wikiPattern) {
        $content = $content -replace '\[\[([^\|\]]+)\|([^\]]+)\]\]', '[$1]($2.md)'
        $issues += "Wiki链接转换([[显示|链接]])"
        $result.issues_summary.wiki_links_fixed++
        $modified = $true
    }

    $simpleWikiPattern = '\[\[([^\]]+)\]\]'
    if ($content -match $simpleWikiPattern) {
        $content = $content -replace '\[\[([^\]]+)\]\]', '[$1]($1.md)'
        $issues += "Wiki链接转换([[链接]])"
        $result.issues_summary.wiki_links_fixed++
        $modified = $true
    }

    # 5. 检查题干完整性
    if ($content -notmatch 'A\.\s' -or $content -notmatch 'B\.\s' -or
        $content -notmatch 'C\.\s' -or $content -notmatch 'D\.\s') {
        $issues += "题干缺少选项"
        $result.issues_summary.incomplete_questions++
    }

    # 6. 检测重复文件
    $questionText = ($content -split '---')[2]
    if ($questionText) {
        $hash = ($questionText -replace '\s', '').GetHashCode()
        if ($questionContents.ContainsKey($hash)) {
            $result.duplicates_found += @{
                files = @($questionContents[$hash], $file.Name)
            }
        } else {
            $questionContents[$hash] = $file.Name
        }
    }

    # 保存修改
    if ($modified) {
        Set-Content -Path $file.FullName -Value $content -Encoding UTF8 -NoNewline
        $result.files_modified += @{
            file = $file.Name
            issues = $issues
        }
    }
}

$result | ConvertTo-Json -Depth 5 -Compress
