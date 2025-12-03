param ($docSysConfigurationFilePath, $component)
if (Test-Path -Path $docSysConfigurationFilePath | -eq $False) {
    Write-Host "DocSys Configuration file not found."
    Exit
}