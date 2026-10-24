param([ValidateSet('windows-debug', 'windows-release')][string]$Preset = 'windows-debug')
$ErrorActionPreference = 'Stop'
if (!(Test-Path "$env:TILO_QT/bin/qmake.exe")) { throw 'Set TILO_QT to the Qt 6.10.2 MinGW kit directory.' }
if (!(Test-Path "$env:TILO_MINGW/bin/g++.exe")) { throw 'Set TILO_MINGW to the matching MinGW 13.1 directory.' }
Push-Location (Split-Path $PSScriptRoot -Parent)
try {
    & cmake --preset $Preset
    if ($LASTEXITCODE -ne 0) { throw 'CMake configure failed.' }
    & cmake --build --preset $Preset --parallel 4
    if ($LASTEXITCODE -ne 0) { throw 'CMake build failed.' }
} finally { Pop-Location }
