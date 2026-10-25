# Run from the root of RiderShield_Apple_SOS in Android Studio PowerShell Terminal.
$ErrorActionPreference = 'Stop'
$flutter = 'C:\Users\majdo\Downloads\flutter\flutter\bin\flutter.bat'
if (-not (Test-Path $flutter)) {
  $flutter = (Get-Command flutter -ErrorAction Stop).Source
}
& $flutter create --platforms=android .
if ($LASTEXITCODE -ne 0) { throw 'Flutter project generation failed.' }
$manifest = Join-Path (Get-Location) 'android\app\src\main\AndroidManifest.xml'
if (-not (Test-Path $manifest)) { throw 'Android manifest was not generated.' }
$content = Get-Content $manifest -Raw
$permissions = @(
  'android.permission.INTERNET',
  'android.permission.ACCESS_COARSE_LOCATION',
  'android.permission.ACCESS_FINE_LOCATION'
)
foreach ($name in $permissions) {
  if (-not $content.Contains('android:name="' + $name + '"')) {
    $item = '    <uses-permission android:name="' + $name + '" />'
    $content = $content -replace '(<manifest\b[^>]*>)', ('$1' + "`n" + $item)
  }
}
[System.IO.File]::WriteAllText($manifest, $content, (New-Object System.Text.UTF8Encoding($false)))
& $flutter pub get
if ($LASTEXITCODE -ne 0) { throw 'flutter pub get failed.' }
Write-Host 'Android project and manifest configured. Open emulator and run Flutter.' -ForegroundColor Green
