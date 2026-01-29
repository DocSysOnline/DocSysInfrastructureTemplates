param ($docSysConfigurationFilePath, $deployPackageAccessToken, $deployPackageDirectory)
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
            $downloadUri = "https://docsysdeploysg.blob.core.windows.net/deployment-container/$client-$componentName/$number/$componentName.zip?$deployPackageAccessToken"
        }
        else {
            $downloadUri = "https://docsysdeploysg.blob.core.windows.net/deployment-container/$componentName/$number/$componentName.zip?$deployPackageAccessToken"
        }
        Invoke-WebRequest -Uri $downloadUri -OutFile "$componentName.zip"
        Expand-Archive -Path "$componentName.zip" -DestinationPath "$deployPackageDirectory/$componentName"

        Write-Host "Downloaded $componentName version: $number for client: $client"

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
                    $downloadUri = "https://docsysdeploysg.blob.core.windows.net/deployment-container/Plugins/$client-$pluginName/$number/$pluginName.zip?$deployPackageAccessToken"
                }
                else {
                    $downloadUri = "https://docsysdeploysg.blob.core.windows.net/deployment-container/Plugins/$pluginName/$number/$pluginName.zip?$deployPackageAccessToken"
                }
                Invoke-WebRequest -Uri $downloadUri -OutFile "$pluginName.zip"
                Expand-Archive -Path "$pluginName.zip" -DestinationPath "$deployPackageDirectory/Plugins/$componentName/$pluginName"

                Write-Host "Downloaded $pluginName version: $number for client: $client"
            }
        }
    }
}