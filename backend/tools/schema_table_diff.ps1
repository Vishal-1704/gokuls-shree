param(
  [Parameter(Mandatory=$true)]
  [string]$LegacySqlPath,

  [Parameter(Mandatory=$true)]
  [string[]]$TargetSqlPaths
)

function Get-TablesFromSql {
  param([string[]]$Paths)

  $tables = @()
  $matches = Select-String -Path $Paths -Pattern 'CREATE TABLE' -CaseSensitive:$false
  foreach ($m in $matches) {
    $line = $m.Line
    if ($line -match 'CREATE TABLE\s+(IF NOT EXISTS\s+)?([^\(\s]+)') {
      $name = $Matches[2].Trim('`','"').ToLower()
      if ($name) { $tables += $name }
    }
  }
  return $tables | Sort-Object -Unique
}

$legacyTables = Get-TablesFromSql -Paths @($LegacySqlPath)
$targetTables = Get-TablesFromSql -Paths $TargetSqlPaths

$missingInTarget = $legacyTables | Where-Object { $_ -notin $targetTables }
$extraInTarget = $targetTables | Where-Object { $_ -notin $legacyTables }

Write-Output ("LEGACY_COUNT=" + $legacyTables.Count)
Write-Output ("TARGET_COUNT=" + $targetTables.Count)
Write-Output "----MISSING_IN_TARGET----"
$missingInTarget
Write-Output "----EXTRA_IN_TARGET----"
$extraInTarget
