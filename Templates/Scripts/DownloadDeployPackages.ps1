param ($docSysConfigurationFilePath)
if (-not (Test-Path -Path $docSysConfigurationFilePath)) {
    Write-Host -ForegroundColor Red "DocSys Configuration file not found."
    Exit
}

$configuration = Get-Content $docSysConfigurationFilePath -Raw | ConvertFrom-Json
$configuration.PSObject.Properties | ForEach-Object {
    if ($_.Name -ne 'General')
    {
        $uri = "https://docsysdeploysg.blob.core.windows.net/deployment-container/UWV-($($_.Name)/$($_.Version.Number)?$env:DeployPackageAccessToken"
        Write-Host $uri

        Invoke-WebRequest -Uri $uri -OutFile "$($_.Name).zip"
    }
}


# foreach ($component in $configuration) {
#     Write-Host $component
# }

# $plugins = $configuration."$component".Plugins
# if($null -ne $plugins)
# {
#     New-Item "$component\bin\Plugins" -ItemType Directory
#     foreach ($plugin in $plugins) {
#         Copy-Item -Path "Plugins\$component\$($plugin.Name).dll" -Destination "$component\bin\Plugins"
#         Write-Host "Copied plugin $($plugin.Name) to component $component"
#     }
# }