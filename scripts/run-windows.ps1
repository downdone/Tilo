param([ValidateSet('windows-debug', 'windows-release')][string]$Preset = 'windows-debug')
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$executable = Join-Path $projectRoot "build/$Preset/bin/tilo.exe"
if (!(Test-Path $executable)) { throw 'Build Tilo first.' }
if (!(Test-Path "$env:TILO_QT/bin/Qt6Core.dll")) { throw 'Set TILO_QT to the Qt kit directory.' }
$originalPath = $env:PATH
try {
    $env:PATH = "$env:TILO_MINGW/bin;$env:TILO_QT/bin;$originalPath"
    Start-Process -FilePath $executable -WorkingDirectory $projectRoot -WindowStyle Hidden
} finally { $env:PATH = $originalPath }
