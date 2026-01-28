param ($docSysConfigurationFilePath, $component)
if (-not (Test-Path -Path $docSysConfigurationFilePath)) {
    Write-Host -ForegroundColor Red "DocSys Configuration file not found."
    Exit
}

$configurationFileName = Split-Path $docSysConfigurationFilePath -Leaf
$configurationDirectory = Split-Path $docSysConfigurationFilePath -Parent

$parts = $configurationFileName -split '\.'
if($parts.count -eq 2) {
    $configuration = Get-Content $docSysConfigurationFilePath -Raw | ConvertFrom-Json
}
elseif($parts.count -eq 3) {
    $rootFilePath = $configurationDirectory + '\' + $parts[0] + '.'  + $parts[2]

    if (-not (Test-Path -Path $rootFilePath)) {
        Write-Output -ForegroundColor Yellow "DocSys root Configuration file not found. Using regular configuration file."
        $configuration = Get-Content $docSysConfigurationFilePath -Raw | ConvertFrom-Json
    }
    else {
        $configuration = Get-Content $rootFilePath -Raw | ConvertFrom-Json
    }
}
else {
    Throw "Only configurations filenames with 2 or 3 dots supported"
}

$languages = $configuration.$General.$Languages
if($null -ne $languages)
{
    # New-Item "$component\bin\Plugins" -ItemType Directory
    # foreach ($plugin in $plugins) {
    #     Copy-Item -Path "Plugins\$component\$($plugin.Name).dll" -Destination "$component\bin\Plugins"
    #     Write-Host "Copied plugin $($plugin.Name) to component $component"
    # }
}

if(Test-Path -Path "$component\Resources")
{
    Remove-Item -Path "$component\Resources"
}
