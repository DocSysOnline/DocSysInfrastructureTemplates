param ($docSysConfigurationFilePath, $deployPackageFileshare, $deployPackageDirectory)
if (-not (Test-Path -Path $docSysConfigurationFilePath)) {
    Write-Host -ForegroundColor Red "DocSys Configuration file not found."
    Exit
}

$configuration = Get-Content $docSysConfigurationFilePath -Raw | ConvertFrom-Json
$configuration.PSObject.Properties | ForEach-Object {
    if ($_.Name -ne 'General')
    {
        $componentName = $_.Name
        $number = $_.Value.Version.Number
        
        if([bool]($_.Value.Version.PSobject.Properties.name -match "Client")) {
            $client = $_.Value.Version.Client
            $fileUri = "$deployPackageFileshare/$client-$componentName/$number/$componentName.zip"
        }
        else {
            $fileUri = "$deployPackageFileshare/$componentName/$number/$componentName.zip"
        }
        Copy-Item -Path $fileUri -Destination "$componentName.zip"
        Expand-Archive -Path "$componentName.zip" -Destination "$deployPackageDirectory/$componentName"

        Write-Host "Copied $componentName version: $number for client: $client"

        if([bool]($_.Value.PSobject.Properties.name -match "Plugins"))
        {
            foreach($plugin in $_.Value.Plugins)
            {
                if (-not(Test-Path $deployPackageDirectory/Plugins -PathType Container)) {
                    New-Item -path $deployPackageDirectory/Plugins -ItemType Directory
                }

                if (-not(Test-Path $deployPackageDirectory/Plugins/$componentName -PathType Container)) {
                    New-Item -path $deployPackageDirectory/Plugins/$componentName -ItemType Directory
                }

                $pluginName = $plugin.Name
                $number = $plugin.Version.Number
                $client = $null

                if([bool]($plugin.Version.PSobject.Properties.name -match "Client")) {
                    $client = $_.Value.Version.Client
                    $fileUri = "$deployPackageFileshare/Plugins/$client-$pluginName/$number/$pluginName.zip"
                }
                else {
                    $fileUri = "$deployPackageFileshare/Plugins/$pluginName/$number/$pluginName.zip"
                }
                Copy-Item -Path $fileUri -Destination "$pluginName.zip"
                Expand-Archive -Path "$pluginName.zip" -DestinationPath "$deployPackageDirectory/Plugins/$componentName/$pluginName"

                Write-Host "Downloaded $pluginName version: $number for client: $client"
            }
        }
    }
}