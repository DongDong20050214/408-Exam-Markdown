<#
  fix_index_links.ps1 — 修复 04-索引视图 下索引文件的链接
  索引里的链接显示文本含「YYYY年第NN题」，但 URL 多为占位名(未分类/线性表)或反斜杠路径，大量断链。
  做法：从显示文本提取 (年份,题号)，到题库按题号定位真实文件，重写为正确相对路径(正斜杠)。
  题号唯一 -> 可靠匹配；匹配不到的保留原样并记日志。默认 dry-run，加 -Apply 写入。
#>
param([switch]$Apply)
$ErrorActionPreference = "Stop"
$root = "C:\Users\86172\Documents\Obsidian Vault\408真题知识库"
$indexDir = "$root\408题库\04-索引视图"

# 建 (年份-题号) -> 题库真实文件 索引（选择题+综合题；题号去前导0归一化）
$qIndex = @{}
$dirs = @("$root\408题库\02-按知识点-选择题", "$root\408题库\03-按知识点-综合题")
foreach ($d in $dirs) {
  if (-not (Test-Path -LiteralPath $d)) { continue }
  foreach ($f in (Get-ChildItem -LiteralPath $d -Recurse -Filter *.md -File)) {
    if ($f.BaseName -match '(\d{4})年第0*(\d+)题') {
      $k = "{0}-{1}" -f $matches[1], [int]$matches[2]
      if (-not $qIndex.ContainsKey($k)) { $qIndex[$k] = $f.FullName }
    }
  }
}
Write-Host ("题库题号索引: {0} 条" -f $qIndex.Count)

$changed = 0; $fixed = 0; $unresolved = New-Object System.Collections.ArrayList; $preview = 0
foreach ($f in (Get-ChildItem -LiteralPath $indexDir -Filter *.md -File)) {
  $raw = Get-Content -LiteralPath $f.FullName -Raw -Encoding UTF8
  if ($null -eq $raw) { continue }
  $dir = $f.DirectoryName
  $new = [regex]::Replace($raw, '\[([^\]]*)\]\(([^)]*\.md)\)', {
    param($m)
    $text = $m.Groups[1].Value
    if ($text -match '(\d{4})年第0*(\d+)题') {
      $k = "{0}-{1}" -f $matches[1], [int]$matches[2]
      if ($qIndex.ContainsKey($k)) {
        $rel = ([System.IO.Path]::GetRelativePath($dir, $qIndex[$k])) -replace '\\','/'
        $script:fixed++
        return "[$text]($rel)"
      }
    }
    [void]$script:unresolved.Add("$($f.Name) :: $($m.Value)")
    return $m.Value
  })
  if ($new -ne $raw) {
    $changed++
    if ($preview -lt 12) {
      $o = [regex]::Match($raw,  '\[[^\]]*\]\([^)]*\.md\)').Value
      $n = [regex]::Match($new,  '\[[^\]]*\]\([^)]*\.md\)').Value
      Write-Host ("[~] {0}: {1}" -f $f.Name, $n) -ForegroundColor Green
      $preview++
    }
    if ($Apply) { Set-Content -LiteralPath $f.FullName -Value $new -Encoding UTF8 -NoNewline }
  }
}
$unresolved | Set-Content -LiteralPath "$root\_index_unresolved.log" -Encoding UTF8
Write-Host ("`n模式={0}  改写文件={1}  修复链接={2}  未匹配={3}" -f $(if($Apply){"APPLY"}else{"DRY-RUN"}), $changed, $fixed, $unresolved.Count)
Write-Host "未匹配清单: _index_unresolved.log"
