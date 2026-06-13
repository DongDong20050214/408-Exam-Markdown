<#
  add_synth_year_links.ps1 — 给综合题新增指向真题原卷的年份链接
  在 03-按知识点-综合题 下每个 "# YYYY年第NN题" 标题后插入一行真题出处链接。
  幂等：已含“真题出处”或已有 01-真题原卷 链接则跳过。默认 dry-run，加 -Apply 写入。
#>
param([switch]$Apply)
$ErrorActionPreference = "Stop"
$root = "C:\Users\86172\Documents\Obsidian Vault\408真题知识库"
$synthDir = "$root\408题库\03-按知识点-综合题"
$yuanjuanDir = "$root\408题库\01-真题原卷"

$changed = 0; $skipped = 0; $preview = 0
foreach ($f in (Get-ChildItem -LiteralPath $synthDir -Recurse -Filter *.md -File)) {
    $raw = Get-Content -LiteralPath $f.FullName -Raw -Encoding UTF8
    if ($null -eq $raw) { continue }
    # 幂等：已处理过
    if ($raw -match '真题出处' -or $raw -match '01-真题原卷') { $skipped++; continue }
    # 从文件名取年份与题号
    if ($f.BaseName -notmatch '(\d{4})年第(\d+)题') { $skipped++; continue }
    $year = $matches[1]; $num = $matches[2]
    $target = Join-Path $yuanjuanDir "$year`年408真题.md"
    if (-not (Test-Path -LiteralPath $target)) { $skipped++; continue }
    $rel = ([System.IO.Path]::GetRelativePath($f.DirectoryName, $target)) -replace '\\','/'
    $linkLine = "**真题出处**：[$year`年第$num`题]($rel#$num)"

    # 在 "# YYYY年第NN题" 标题行后插入
    $pattern = '(?m)^(#\s*' + [regex]::Escape($year) + '年第' + [regex]::Escape($num) + '题.*)$'
    if ($raw -match $pattern) {
        $new = [regex]::Replace($raw, $pattern, "`$1`r`n`r`n$linkLine", 1)
    } else {
        # 没有标准标题，则插到 frontmatter 之后或文件开头
        if ($raw -match '(?s)^(---.*?---\r?\n)') {
            $fm = $matches[1]
            $new = $fm + "`r`n$linkLine`r`n" + $raw.Substring($fm.Length)
        } else {
            $new = "$linkLine`r`n`r`n" + $raw
        }
    }

    if ($new -ne $raw) {
        $changed++
        if ($preview -lt 6) {
            Write-Host ("[+] {0}" -f $f.Name) -ForegroundColor Green
            Write-Host ("    {0}" -f $linkLine) -ForegroundColor DarkGray
            $preview++
        }
        if ($Apply) { Set-Content -LiteralPath $f.FullName -Value $new -Encoding UTF8 -NoNewline }
    }
}
Write-Host ("`n模式={0}  新增链接文件={1}  跳过={2}" -f $(if($Apply){"APPLY"}else{"DRY-RUN"}), $changed, $skipped)
