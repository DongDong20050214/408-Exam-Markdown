$rootDir = "C:\Users\86172\Documents\Obsidian Vault\408真题知识库"
$count = 0

function Convert-WikiLink {
    param($content, $currentFilePath)

    $pattern = '\[\[([^\]]+?)\]\]'

    return [regex]::Replace($content, $pattern, {
        param($match)
        $linkText = $match.Groups[1].Value

        # 处理带显示文本的链接 [[文件名|显示文本]]
        if ($linkText -match '^(.+?)\|(.+?)$') {
            $target = $matches[1].Trim()
            $display = $matches[2].Trim()
        } else {
            $target = $linkText.Trim()
            $display = $target
        }

        $currentDir = Split-Path $currentFilePath -Parent

        # 判断链接类型并生成相对路径
        if ($target -match '^\d{4}年第\d+题') {
            # 题目链接：在408题库中查找
            $possiblePaths = @(
                "408题库\01-按年份-选择题",
                "408题库\02-按知识点-选择题",
                "408题库\03-按年份-综合题",
                "408题库\04-按知识点-综合题"
            )

            foreach ($dir in $possiblePaths) {
                $searchPath = Join-Path $rootDir $dir
                $found = Get-ChildItem -Path $searchPath -Recurse -Filter "$target.md" -ErrorAction SilentlyContinue | Select-Object -First 1
                if ($found) {
                    $relPath = [System.IO.Path]::GetRelativePath($currentDir, $found.FullName)
                    return "[$display]($relPath)"
                }
            }
        } elseif ($target -notmatch '^\d{4}年') {
            # 知识点链接：在AI-知识点原子库中查找
            $searchPath = Join-Path $rootDir "AI-知识点原子库"
            if (Test-Path $searchPath) {
                $found = Get-ChildItem -Path $searchPath -Recurse -Filter "$target.md" -ErrorAction SilentlyContinue | Select-Object -First 1
                if ($found) {
                    $relPath = [System.IO.Path]::GetRelativePath($currentDir, $found.FullName)
                    return "[$display]($relPath)"
                }
            }
        }

        # 同目录查找
        $sameDirPath = Join-Path $currentDir "$target.md"
        if (Test-Path $sameDirPath) {
            return "[$display]($target.md)"
        }

        # 未找到时保留原格式
        return $match.Value
    })
}

# 获取所有包含Wiki链接的文件
$files = Get-ChildItem -Path $rootDir -Recurse -Filter "*.md" | Where-Object {
    (Get-Content $_.FullName -Raw -ErrorAction SilentlyContinue) -match '\[\[.+?\]\]'
}

foreach ($file in $files) {
    try {
        $content = Get-Content $file.FullName -Raw -Encoding UTF8
        $newContent = Convert-WikiLink $content $file.FullName

        if ($content -ne $newContent) {
            Set-Content -Path $file.FullName -Value $newContent -Encoding UTF8 -NoNewline
            $count++
            if ($count % 100 -eq 0) {
                Write-Host "100"
            }
        }
    } catch {
        Write-Warning "处理文件失败: $($file.FullName) - $_"
    }
}

Write-Host "`n总计转换 $count 个文件"
