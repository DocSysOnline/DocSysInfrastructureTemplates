param ($mustacheConfigurationFilePath)
# Install-PackageProvider -Name NuGet -Force -Scope CurrentUser
Install-Module -Name PSMustache -Scope CurrentUser -Force
if (Test-Path -Path $mustacheConfigurationFilePath) {
    Write-Host "Configuration file found."
    $values = Get-Content $mustacheConfigurationFilePath | ConvertFrom-Json

    Get-ChildItem -Recurse -Include *.mustache -Name | ForEach-Object {
        $configuredFile = $_.Replace('.mustache','') 
        $template = Get-Content $_ | Out-String; ConvertFrom-MustacheTemplate -Template $template -Values $values | Out-File -FilePath $configuredFile
        Write-Output "Configurationfile $configuredFile created."
    }
}