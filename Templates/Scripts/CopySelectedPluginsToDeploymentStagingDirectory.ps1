param ($docSysConfigurationFilePath, $component)
if (-not (Test-Path -Path $docSysConfigurationFilePath)) {
    Write-Host -ForegroundColor Red "DocSys Configuration file not found."
    Exit
}

$configuration = Get-Content $docSysConfigurationFilePath | ConvertFrom-Json
$plugins = $configuration."$component".Plugins
if($null -ne $plugins)
{
    New-Item "$component\bin\Plugins" -ItemType Directory
    foreach ($plugin in $plugins) {
        Copy-Item -Path "Plugins\$component\$plugin" -Destination "$component\bin\Plugins"
        Write-Host "Copied plugin $plugin to component $component"
    }
}