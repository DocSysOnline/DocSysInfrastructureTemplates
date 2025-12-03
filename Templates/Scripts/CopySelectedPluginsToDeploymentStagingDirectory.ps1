param ($docSysConfigurationFilePath, $component)
if (-not (Test-Path -Path $docSysConfigurationFilePath)) {
    Write-Host "DocSys Configuration file not found."
    Exit
}