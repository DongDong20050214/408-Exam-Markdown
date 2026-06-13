<#
  fix_links_v2.ps1  —  保守修复 408真题知识库 的坏 Markdown 链接
  ---------------------------------------------------------------
  只处理指向笔记/目录的 [text](url) 链接；绝不碰图片 ![..](..)、<img>、http(s)、[[wikilink]]。
  逻辑：解析 url -> 去别名(|后)、分离锚点(#)、取文件名 -> 在全库索引里精确定位 -> 重算相对路径。
  定位不到的链接：原样保留，并记入“未解析清单”。
  默认 dry-run（不改文件）。加 -Apply 才真正写入。
#>
param(
    [switch]$Apply,         # 不加=dry-run；加了才写文件
    [int]$PreviewLimit = 40,
    [string]$File = ""      # 指定单文件测试（绝对路径）
)

$ErrorActionPreference = "Stop"
$root = "C:\Users\86172\Documents\Obsidian Vault\408真题知识库"

# ---- 1. 建立 文件名(无扩展) -> 完整路径列表 的索引 ----
# 只递归内容目录，跳过 .obsidian / .git（避免遍历插件 node_modules 超时）
Write-Host "建立全库索引..." -ForegroundColor Cyan
$index = @{}
$allMd = New-Object System.Collections.ArrayList
foreach ($x in (Get-ChildItem -LiteralPath $root -Filter *.md -File)) { [void]$allMd.Add($x) }
$scanDirs = Get-ChildItem -LiteralPath $root -Directory | Where-Object { $_.Name -notmatch '^\.(obsidian|git|trash)$' }
foreach ($d in $scanDirs) {
    foreach ($x in (Get-ChildItem -LiteralPath $d.FullName -Recurse -Filter *.md -File)) { [void]$allMd.Add($x) }
}
foreach ($f in $allMd) {
    $b = $f.BaseName
    if (-not $index.ContainsKey($b)) { $index[$b] = New-Object System.Collections.ArrayList }
    [void]$index[$b].Add($f.FullName)
}
Write-Host ("索引完成：{0} 个 .md，{1} 个唯一文件名" -f $allMd.Count, $index.Count)

# ---- 2. 链接重写函数 ----
# 返回 @{ text=新文本; unresolved=@(未解析原串) }
function Rewrite-Links {
    param([string]$content, [string]$currentFile)

    $script:unresolvedThisFile = New-Object System.Collections.ArrayList
    $currentDir = Split-Path $currentFile -Parent

    # 非图片的 md 链接：前一字符不是 ! ；捕获 text 与 url
    $pattern = '(?<!\!)\[([^\]]*)\]\(([^)]+)\)'

    $newContent = [regex]::Replace($content, $pattern, {
        param($m)
        $text = $m.Groups[1].Value
        $url  = $m.Groups[2].Value
        $orig = $m.Value

        # 跳过：外链 / 纯锚点 / 协议链接
        if ($url -match '^(https?://|mailto:|#|ftp://)') { return $orig }

        # 只处理“坏味道”链接：含 | 残留、或指向 .md、或以 / 结尾(目录)
        $looksLikeNoteLink = ($url -match '\|') -or ($url -match '\.md(\#|$|\))') -or ($url -match '\.md$') -or ($url -match '/$')
        if (-not $looksLikeNoteLink) { return $orig }

        # 取 | 之前为真实目标（| 后是被误塞进 URL 的别名）
        $rawTarget = $url
        if ($rawTarget -match '^(.*?)\|') { $rawTarget = $matches[1] }

        # 反斜杠 -> 正斜杠
        $rawTarget = $rawTarget -replace '\\', '/'

        # 目录链接（以 / 结尾）：去掉别名与 .md，直接指向目录
        if ($rawTarget -match '/$') {
            $disp = Get-Display $text $rawTarget
            return "[$disp]($rawTarget)"
        }

        # 去掉结尾 .md
        $rawTarget = $rawTarget -replace '\.md$', ''

        # 分离锚点 #
        $anchor = ""
        if ($rawTarget -match '^(.*?)\#(.*)$') {
            $rawTarget = $matches[1]
            $anchor = $matches[2]
        }
        if ([string]::IsNullOrWhiteSpace($rawTarget)) { return $orig }

        # 取文件名（最后一段）
        $baseName = Split-Path $rawTarget -Leaf

        # 在索引中精确定位
        if (-not $index.ContainsKey($baseName)) {
            [void]$script:unresolvedThisFile.Add($orig)
            return $orig
        }
        $candidates = $index[$baseName]
        $targetPath = $null
        if ($candidates.Count -eq 1) {
            $targetPath = $candidates[0]
        } else {
            # 多义消歧：用原 path 的中间目录线索匹配
            $hintParts = ($rawTarget -split '/') | Where-Object { $_ -ne '' -and $_ -ne '..' -and $_ -ne '.' }
            $best = $candidates | Where-Object {
                $cand = $_
                ($hintParts | Where-Object { $cand -like "*$_*" }).Count -eq $hintParts.Count
            }
            if (@($best).Count -eq 1) { $targetPath = @($best)[0] }
            else {
                [void]$script:unresolvedThisFile.Add($orig)
                return $orig
            }
        }

        # 计算相对路径（正斜杠）
        $rel = [System.IO.Path]::GetRelativePath($currentDir, $targetPath) -replace '\\', '/'

        # 显示文本
        $disp = Get-Display $text $rawTarget

        if ($anchor -ne "") { return "[$disp]($rel#$anchor)" }
        else { return "[$disp]($rel)" }
    })

    return @{ text = $newContent; unresolved = $script:unresolvedThisFile }
}

# 决定显示文本：text 含 | 取 | 后；否则若 text 是路径形式取其末段；否则原样
function Get-Display {
    param([string]$text, [string]$target)
    if ($text -match '\|') { return ($text -replace '^.*\|', '').Trim() }
    if ($text -match '/') { return (Split-Path ($text -replace '\\','/') -Leaf) }
    return $text
}

# ---- 3. 主循环 ----
$targets = if ($File -ne "") { Get-ChildItem -Path $File -File } else { $allMd }
# 排除脚本自身与执行指令文档（含示例文本，避免误伤）
$targets = $targets | Where-Object { $_.Extension -eq ".md" -and $_.Name -ne "下一个对话执行指令.md" }

$totalChanged = 0
$totalLinksFixed = 0
$allUnresolved = New-Object System.Collections.ArrayList
$previewShown = 0

foreach ($f in $targets) {
    $raw = Get-Content -LiteralPath $f.FullName -Raw -Encoding UTF8
    if ($null -eq $raw) { continue }
    $res = Rewrite-Links $raw $f.FullName
    foreach ($u in $res.unresolved) { [void]$allUnresolved.Add("$($f.Name) :: $u") }

    if ($res.text -ne $raw) {
        $totalChanged++
        # 统计本文件修复的链接数（按行 diff 粗略计）
        $before = ([regex]::Matches($raw, '(?<!\!)\[[^\]]*\]\([^)]+\)')).Count
        # 预览前若干条
        if ($previewShown -lt $PreviewLimit) {
            $rel = $f.FullName.Substring($root.Length).TrimStart('\')
            Write-Host "`n--- $rel ---" -ForegroundColor Yellow
            # 显示发生变化的链接对照
            $oldLinks = [regex]::Matches($raw,  '(?<!\!)\[[^\]]*\]\([^)]+\)') | ForEach-Object { $_.Value }
            $newLinks = [regex]::Matches($res.text, '(?<!\!)\[[^\]]*\]\([^)]+\)') | ForEach-Object { $_.Value }
            for ($i=0; $i -lt [Math]::Min($oldLinks.Count,$newLinks.Count); $i++) {
                if ($oldLinks[$i] -ne $newLinks[$i]) {
                    Write-Host ("  - 旧: {0}" -f $oldLinks[$i]) -ForegroundColor DarkGray
                    Write-Host ("  + 新: {0}" -f $newLinks[$i]) -ForegroundColor Green
                    $previewShown++
                    $totalLinksFixed++
                    if ($previewShown -ge $PreviewLimit) { break }
                }
            }
        }
        if ($Apply) {
            Set-Content -LiteralPath $f.FullName -Value $res.text -Encoding UTF8 -NoNewline
        }
    }
}

Write-Host "`n================ 汇总 ================" -ForegroundColor Cyan
Write-Host ("模式            : {0}" -f $(if($Apply){"已应用(写入)"}else{"DRY-RUN(未写入)"}))
Write-Host ("发生修改的文件  : {0}" -f $totalChanged)
Write-Host ("未解析链接条数  : {0}" -f $allUnresolved.Count)

# 写未解析清单到文件供复核
$logPath = Join-Path $root "_link_unresolved.log"
$allUnresolved | Set-Content -LiteralPath $logPath -Encoding UTF8
Write-Host ("未解析清单已写入: {0}" -f $logPath)
