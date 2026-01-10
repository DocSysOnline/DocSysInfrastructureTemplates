param ($docSysConfigurationFilePath, $deployPackageAccessToken, $deployPackageDirectory)
if (-not (Test-Path -Path $docSysConfigurationFilePath)) {
    Write-Host -ForegroundColor Red "DocSys Configuration file not found."
    Exit
}

$configuration = Get-Content $docSysConfigurationFilePath -Raw | ConvertFrom-Json
$configuration.PSObject.Properties | ForEach-Object {
    if ($_.Name -ne 'General')
    {
        $name = $_.Name
        $number = $_.Value.Version.Number
        
        if([bool]($_.Value.Version.PSobject.Properties.name -match "Client")) {
            $client = $_.Value.Version.Client
            $downloadUri = "https://docsysdeploysg.blob.core.windows.net/deployment-container/$client-$name/$number/$name.zip?$deployPackageAccessToken"
        }
        else {
            $downloadUri = "https://docsysdeploysg.blob.core.windows.net/deployment-container/$name/$number/$name.zip?$deployPackageAccessToken"
        }
        Invoke-WebRequest -Uri $downloadUri -OutFile "$name.zip"
        Expand-Archive -Path "$name.zip" -DestinationPath "$deployPackageDirectory/$name"

        Write-Host "Downloaded $name version: $number for client: $client"

        if([bool]($_.Value.PSobject.Properties.name -match "Plugins"))
        {
            foreach($plugin in $_.Value.Plugins)
            {



                $name = $plugin.Name
                $number = $plugin.Version.Number

                if([bool]($plugin.Version.PSobject.Properties.name -match "Client")) {
                    $client = $_.Value.Version.Client
                    $downloadUri = "https://docsysdeploysg.blob.core.windows.net/deployment-container/Plugins/$client-$name/$number/$name.dll?$deployPackageAccessToken"
                }
                else {
                    $downloadUri = "https://docsysdeploysg.blob.core.windows.net/deployment-container/Plugins/$name/$number/$name.dll?$deployPackageAccessToken"
                }
                Write-Host $downloadUri
                Invoke-WebRequest -Uri $downloadUri -OutFile "$deployPackageDirectory/Plugins/$name.dll" -Force

                Write-Host "Downloaded $name version: $number for client: $client"
            }
        }
    }
}