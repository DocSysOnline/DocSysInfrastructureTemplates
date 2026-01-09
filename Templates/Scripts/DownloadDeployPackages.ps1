param ($docSysConfigurationFilePath)
if (-not (Test-Path -Path $docSysConfigurationFilePath)) {
    Write-Host -ForegroundColor Red "DocSys Configuration file not found."
    Exit
}

$configuration = Get-Content $docSysConfigurationFilePath -Raw | ConvertFrom-Json
# $plugins = $configuration."$component".Plugins
# if($null -ne $plugins)
# {
#     New-Item "$component\bin\Plugins" -ItemType Directory
#     foreach ($plugin in $plugins) {
#         Copy-Item -Path "Plugins\$component\$($plugin.Name).dll" -Destination "$component\bin\Plugins"
#         Write-Host "Copied plugin $($plugin.Name) to component $component"
#     }
# }