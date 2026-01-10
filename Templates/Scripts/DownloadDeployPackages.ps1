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
        $client = $_.Value.Version.Client
        $number = $_.Value.Version.Number

        $downloadUri = "https://docsysdeploysg.blob.core.windows.net/deployment-container/$client-$name/$number/$name.zip?$deployPackageAccessToken"
        Invoke-WebRequest -Uri $downloadUri -OutFile "$name.zip"

        Expand-Archive -Path "$name.zip" -DestinationPath "$deployPackageDirectory/DeployPackage/$name"

        Write-Host "Downloaded $name version: $number for client: $uwv"

        if([bool]($_.Value.PSobject.Properties.name -match "Plugins"))
        {
            foreach($plugin in $_.Value.Plugins)
            {
                Write-Host $plugin
            }
        }
    }
}