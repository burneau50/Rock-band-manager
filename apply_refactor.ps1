$ErrorActionPreference = "Stop"
$projectRoot = Get-Location
$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$mainPath = Join-Path $projectRoot "lib\main.dart"
if (Test-Path $mainPath) { $backup = Join-Path $projectRoot "main.dart.backup-$stamp"; Copy-Item $mainPath $backup -Force; Write-Host "Sauvegarde de main.dart : $backup" }
$sourceRoot = Join-Path $PSScriptRoot "lib"
$files = @(
  "main.dart",
  "screens\auth_screen.dart",
  "screens\home_screen.dart",
  "screens\home_song_methods.dart",
  "screens\home_representation_methods.dart",
  "screens\home_ui_methods.dart"
)
foreach ($relative in $files) {
  $src = Join-Path $sourceRoot $relative
  $dst = Join-Path (Join-Path $projectRoot "lib") $relative
  $dir = Split-Path $dst -Parent
  if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
  $same = $false
  if (Test-Path $dst) { $same = ((Resolve-Path $src).Path -eq (Resolve-Path $dst).Path) }
  if ($same) { Write-Host "Deja en place : lib/$($relative -replace '\\','/')" } else { Copy-Item $src $dst -Force; Write-Host "Ecrit : lib/$($relative -replace '\\','/')" }
}
Write-Host "`nRefactorisation V5 appliquee."
Write-Host "Lancez maintenant :"
Write-Host "  flutter analyze"
