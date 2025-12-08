param ($docSysConfigurationFilePath)
Install-Module -Name PSMustache -Scope CurrentUser -Force
Write-Output "Connection $dsoDatabaseConnection"
if (-not (Test-Path -Path $docSysConfigurationFilePath)) {
    Write-Output -ForegroundColor Red "DocSys Configuration file not found."
    Exit
}

$values = Get-Content $docSysConfigurationFilePath | ConvertFrom-Json
$secrets = $args
foreach ($secret in $secrets) {
    $splitSecret = $secret -split '='
    $secretValue = $splitSecret[1]

    $values.DSO.DatabaseConnectionString = $secretValue
    Write-Output $secret
}

Write-Output "Combined configuration input"
Write-Host ($values | ConvertTo-JSON)

Get-ChildItem -Recurse -Include *.mustache -Name | ForEach-Object {
    $configuredFile = $_.Replace('.mustache','') 
    $template = Get-Content $_ | Out-String; ConvertFrom-MustacheTemplate -Template $template -Values $values | Out-File -FilePath $configuredFile -Encoding utf8
    Write-Output "Configurationfile $configuredFile created."
}