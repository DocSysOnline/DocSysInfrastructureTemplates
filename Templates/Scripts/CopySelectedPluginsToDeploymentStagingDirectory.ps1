param ($docSysConfigurationFilePath, $component)
if (-not (Test-Path -Path $docSysConfigurationFilePath)) {
    Write-Host -ForegroundColor Red "DocSys Configuration file not found."
    Exit
}

if ($component -eq "DSO") {
    $plugins = @(
      "DocSysOnline.Plugins.ApiDefinition.dll",
      "DocSysOnline.Plugins.DownloadPlugin.dll",
      "DocSysOnline.Plugins.Flow.dll",
      "DocSysOnline.Plugins.MomPlugin.dll",
      "DocSysOnline.Plugins.StubsPlugin.dll"
    )
    foreach ($plugin in $plugins) {
        Copy-Item -Path Plugins\$component\$plugin -Destination $component\bin\Plugins
        Write-Host "Copied plugin $($plugin) to component $($component)"
    }

    ls DSO\bin
    ls DSO\bin\Plugins
}