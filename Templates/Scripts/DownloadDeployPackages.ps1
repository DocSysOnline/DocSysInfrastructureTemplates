param ($docSysConfigurationFilePath, $deployPackageAccessToken)
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

        Expand-Archive -Path "$name.zip" -DestinationPath "$(Pipeline.Workspace)/Targets/DeployPackage/$name"
    }
}