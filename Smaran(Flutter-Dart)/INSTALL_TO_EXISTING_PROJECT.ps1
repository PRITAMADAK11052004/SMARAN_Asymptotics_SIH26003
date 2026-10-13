$ErrorActionPreference = 'Stop'
$project = 'D:\FlutterDev\projects\smaran_flutter'
if (!(Test-Path $project)) { throw "Flutter project not found: $project" }
Copy-Item -Recurse -Force "$PSScriptRoot\lib" "$project\lib"
Copy-Item -Recurse -Force "$PSScriptRoot\assets" "$project\assets"
Copy-Item -Force "$PSScriptRoot\pubspec.yaml" "$project\pubspec.yaml"
Write-Host "Smaran Flutter source/assets copied." -ForegroundColor Green
Set-Location $project
flutter pub get
Write-Host "Dependencies restored. Run: flutter run" -ForegroundColor Cyan
