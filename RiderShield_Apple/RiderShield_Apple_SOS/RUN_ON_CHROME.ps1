# RiderShield quick start for Windows PowerShell.
# Flutter SDK can be left in Downloads; changing PATH is not required.
$flutterBat = 'C:\Users\majdo\Downloads\flutter\flutter\bin\flutter.bat'
if (-not (Test-Path $flutterBat)) {
  $cmd = Get-Command flutter -ErrorAction SilentlyContinue
  if ($cmd) { $flutterBat = $cmd.Source }
}
if (-not (Test-Path $flutterBat)) {
  Write-Host 'Flutter SDK not found. Update the path at the top of RUN_ON_CHROME.ps1.' -ForegroundColor Red
  exit 1
}
Set-Location $PSScriptRoot
Write-Host 'Creating missing Flutter web scaffold...' -ForegroundColor Cyan
& $flutterBat create --platforms=web .
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
Write-Host 'Fetching Flutter packages...' -ForegroundColor Cyan
& $flutterBat pub get
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
Write-Host 'Opening RiderShield in Chrome...' -ForegroundColor Cyan
& $flutterBat run -d chrome
exit $LASTEXITCODE
