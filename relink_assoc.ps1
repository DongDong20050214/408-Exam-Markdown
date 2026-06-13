<#
  relink_assoc.ps1 — 重写“关联知识”链接，指向 AI-知识点原子库
  对每条 关联知识：[..](知识库/学科/概念.md)：概念经同义/后缀映射或原名解析到 AI 库文件，
  重写为指向 AI-知识点原子库/<文件>.md 的相对链接。解析不到的保留原样并记日志。
  需在知识点笔记补建完成后运行。默认 dry-run，加 -Apply 写入。
#>
param([switch]$Apply)
$ErrorActionPreference = "Stop"
$root = "C:\Users\86172\Documents\Obsidian Vault\408真题知识库"
$aiDir = "$root\AI-知识点原子库"

# AI库现有文件集合
$aiSet = @{}
Get-ChildItem -LiteralPath $aiDir -Filter *.md -File | ForEach-Object { $aiSet[$_.BaseName] = $true }

$syn = @{
  "散列表"="哈希表"; "散列"="哈希表"; "OSI模型"="OSI七层模型"; "TLB"="快表TLB";
  "局部性原理"="程序局部性原理"; "程序局部性"="程序局部性原理"; "KMP"="串的模式匹配";
  "页面置换"="页面置换算法"; "页式管理"="分页存储"; "分页"="分页存储"; "分段"="分段存储";
  "虚拟存储"="虚拟存储器"; "补码"="补码运算"; "缺页"="缺页中断"; "拓扑"="拓扑排序";
  "信号量"="PV操作"; "PV"="PV操作";
  "哈夫曼树"="霍夫曼树"; "最优二叉树"="霍夫曼树"; "二叉排序树"="二叉搜索树";
  "AVL树"="平衡二叉树"; "图遍历"="图的遍历"; "深度优先搜索"="图的遍历";
  "CSMACD"="CSMA-CD"; "顺序表基础"="顺序表"; "双向链表基础"="链表";
  "链表插入删除"="链表"; "完全二叉树"="二叉树"; "树的性质"="二叉树";
}

function Resolve-Concept($c) {
  if ($aiSet.ContainsKey($c)) { return $c }
  if ($syn.ContainsKey($c) -and $aiSet.ContainsKey($syn[$c])) { return $syn[$c] }
  foreach ($suf in @("协议","运算","算法","存储","器","表")) {
    if ($aiSet.ContainsKey("$c$suf")) { return "$c$suf" }
  }
  return $null
}

$changed = 0; $relinked = 0; $unresolved = New-Object System.Collections.ArrayList; $preview = 0
$scan = Get-ChildItem "$root\408题库" -Recurse -Filter *.md -File
foreach ($f in $scan) {
  $raw = Get-Content -LiteralPath $f.FullName -Raw -Encoding UTF8
  if ($null -eq $raw -or $raw -notmatch '知识库/') { continue }
  $dir = $f.DirectoryName
  $new = [regex]::Replace($raw, '\[([^\]]*)\]\(知识库/([^/)]+)/([^)]+?)\.md\)', {
    param($m)
    $concept = $m.Groups[3].Value
    $z = Resolve-Concept $concept
    if (-not $z) { [void]$script:unresolved.Add("$($f.Name) :: $($m.Value)"); return $m.Value }
    $target = Join-Path $aiDir "$z.md"
    $rel = ([System.IO.Path]::GetRelativePath($dir, $target)) -replace '\\','/'
    $script:relinked++
    return "[$z]($rel)"
  })
  if ($new -ne $raw) {
    $changed++
    if ($preview -lt 10) {
      $old = [regex]::Match($raw, '\[[^\]]*\]\(知识库/[^)]+\)').Value
      $nw  = [regex]::Match($new, '关联知识：\[[^\]]*\]\([^)]+\)').Value
      Write-Host ("[~] {0}" -f $f.Name) -ForegroundColor Yellow
      Write-Host ("    新: {0}" -f $nw) -ForegroundColor Green
      $preview++
    }
    if ($Apply) { Set-Content -LiteralPath $f.FullName -Value $new -Encoding UTF8 -NoNewline }
  }
}
$unresolved | Set-Content -LiteralPath "$root\_assoc_unresolved.log" -Encoding UTF8
Write-Host ("`n模式={0}  改写文件={1}  重链条数={2}  未解析={3}" -f $(if($Apply){"APPLY"}else{"DRY-RUN"}), $changed, $relinked, $unresolved.Count)
Write-Host "未解析清单: _assoc_unresolved.log"
