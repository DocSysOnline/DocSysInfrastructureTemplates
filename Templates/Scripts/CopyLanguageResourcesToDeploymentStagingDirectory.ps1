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

Write-Host $configuration
Write-Host $configuration.General
Write-Host $configuration.General.Languages

$languages = $configuration.General.Languages
Write-Host "Selected languages $languages"
if($null -ne $languages)
{
    if(Test-Path -Path "$component\Resources")
    {
        foreach ($language in $languages) {
            Copy-Item -Path "$component\Resources\$language\*" -Destination "$component\bin"
            Write-Host "Copied language $language to component $component"
        }
    }
}

# if(Test-Path -Path "$component\Resources")
# {
#     Remove-Item -Path "$component\Resources" -Recurse
# }
