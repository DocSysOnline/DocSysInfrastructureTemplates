param ($mustacheConfigurationFilePath)
Write-Host $mustacheConfigurationFilePath
if (Test-Path -Path $mustacheConfigurationFilePath) {
    Write-Host "Configuration file found."
}