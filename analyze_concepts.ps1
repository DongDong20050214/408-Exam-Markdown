<#
  analyze_concepts.ps1 — 只读分析关联知识链接的概念集
  输出：去重概念、能映射到现有AI库的、需新建的三类清单 -> _concepts_report.txt
#>
$ErrorActionPreference = "Stop"
$root = "C:\Users\86172\Documents\Obsidian Vault\408真题知识库"

# AI库现有知识点集合
$aiSet = @{}
Get-ChildItem "$root\AI-知识点原子库" -Filter *.md -File | ForEach-Object { $aiSet[$_.BaseName] = $true }

# 手动同义词映射（概念 -> AI库文件名）
$syn = @{
  "散列表"="哈希表"; "散列"="哈希表"; "OSI模型"="OSI七层模型"; "TLB"="快表TLB";
  "局部性原理"="程序局部性原理"; "程序局部性"="程序局部性原理"; "KMP"="串的模式匹配";
  "页面置换"="页面置换算法"; "页式管理"="分页存储"; "分页"="分页存储"; "分段"="分段存储";
  "虚拟存储"="虚拟存储器"; "补码"="补码运算"; "缺页"="缺页中断"; "拓扑"="拓扑排序";
  "三次握手"="三次握手"; "四次挥手"="四次挥手"; "信号量"="PV操作"; "PV"="PV操作";
  "哈夫曼树"="霍夫曼树"; "最优二叉树"="霍夫曼树"; "二叉排序树"="二叉搜索树";
  "AVL树"="平衡二叉树"; "图遍历"="图的遍历"; "深度优先搜索"="图的遍历";
  "CSMACD"="CSMA-CD"; "顺序表基础"="顺序表"; "双向链表基础"="链表";
  "链表插入删除"="链表"; "完全二叉树"="二叉树"; "树的性质"="二叉树";
}

# 尝试映射一个概念到AI库；返回命中的文件名或 $null
function Resolve-Concept($c) {
  if ($aiSet.ContainsKey($c)) { return $c }
  if ($syn.ContainsKey($c) -and $aiSet.ContainsKey($syn[$c])) { return $syn[$c] }
  foreach ($suf in @("协议","运算","算法","存储","器","表")) {
    if ($aiSet.ContainsKey("$c$suf")) { return "$c$suf" }
  }
  foreach ($suf in @("协议","运算","算法","存储")) {
    if ($c.EndsWith($suf)) {
      $stripped = $c.Substring(0, $c.Length - $suf.Length)
      if ($aiSet.ContainsKey($stripped)) { return $stripped }
    }
  }
  return $null
}

# 扫题库提取所有 知识库/学科/概念
$concepts = @{}   # "学科/概念" -> 次数
$scan = Get-ChildItem "$root\408题库" -Recurse -Filter *.md -File
foreach ($f in $scan) {
  $c = Get-Content -LiteralPath $f.FullName -Raw -Encoding UTF8
  if ($null -eq $c) { continue }
  foreach ($m in [regex]::Matches($c, '\(知识库/([^/)]+)/([^)]+?)\.md\)')) {
    $k = $m.Groups[1].Value + "/" + $m.Groups[2].Value
    if ($concepts.ContainsKey($k)) { $concepts[$k]++ } else { $concepts[$k] = 1 }
  }
}

# 分类
$mapped = New-Object System.Collections.ArrayList
$tobuild = New-Object System.Collections.ArrayList
foreach ($kv in $concepts.GetEnumerator()) {
  $parts = $kv.Key -split '/', 2
  $subject = $parts[0]; $concept = $parts[1]
  $hit = Resolve-Concept $concept
  if ($hit) { [void]$mapped.Add(("{0}/{1}  ->  {2}  (x{3})" -f $subject,$concept,$hit,$kv.Value)) }
  else      { [void]$tobuild.Add(("{0}/{1}  (x{2})" -f $subject,$concept,$kv.Value)) }
}

$out = New-Object System.Collections.ArrayList
[void]$out.Add("=== 去重概念总数: $($concepts.Count) ===")
[void]$out.Add("=== 可映射到现有AI库: $($mapped.Count) ===")
$mapped | Sort-Object | ForEach-Object { [void]$out.Add($_) }
[void]$out.Add("")
[void]$out.Add("=== 需新建: $($tobuild.Count) ===")
$tobuild | Sort-Object | ForEach-Object { [void]$out.Add($_) }

$out | Set-Content -LiteralPath "$root\_concepts_report.txt" -Encoding UTF8
Write-Host ("去重概念={0}  可映射={1}  需新建={2}" -f $concepts.Count, $mapped.Count, $tobuild.Count)
Write-Host "清单已写入 _concepts_report.txt"
