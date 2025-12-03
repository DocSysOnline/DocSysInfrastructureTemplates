param ($docSysConfigurationFilePath)
Install-Module -Name PSMustache -Scope CurrentUser -Force
if (-not (Test-Path -Path $docSysConfigurationFilePath)) {
    Write-Host "DocSys Configuration file not found."
    Exit
}

$values = Get-Content $docSysConfigurationFilePath | ConvertFrom-Json

Get-ChildItem -Recurse -Include *.mustache -Name | ForEach-Object {
    $configuredFile = $_.Replace('.mustache','') 
    $template = Get-Content $_ | Out-String; ConvertFrom-MustacheTemplate -Template $template -Values $values | Out-File -FilePath $configuredFile -Encoding utf8
    Write-Output "Configurationfile $configuredFile created."
}