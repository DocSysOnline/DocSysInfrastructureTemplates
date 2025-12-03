param ($docSysConfigurationFilePath, $component)
if (Test-Path -Path $docSysConfigurationFilePath -eq false) {
    Write-Host "DocSys Configuration file not found."
    Exit
}