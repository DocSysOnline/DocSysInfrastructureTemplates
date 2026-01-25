param ($docSysConfigurationFilePath, $reformatJsonOutput = $true)
Install-Module -Name PSMustache -Scope CurrentUser -Force
Install-Module -Name newtonsoft.json -Scope CurrentUser -Force

function Merge-JsonObject {
    param (
        [Parameter(Mandatory)]
        [psobject]$Base,

        [Parameter(Mandatory)]
        [psobject]$Override
    )

    foreach ($prop in $Override.PSObject.Properties) {

        if (
            $Base.PSObject.Properties[$prop.Name] -and
            $Base.$($prop.Name) -is [psobject] -and
            $prop.Value -is [psobject]
        ) {
            # Both values are objects → recurse
            Merge-JsonObject -Base $Base.$($prop.Name) -Override $prop.Value
        }
        else {
            # Override or add
            $Base | Add-Member `
                -NotePropertyName $prop.Name `
                -NotePropertyValue $prop.Value `
                -Force
        }
    }

    return $Base
}

function Format-ConfigurationFiles {
    param ($docSysConfigurationFilePath, $reformatJsonOutput)

    if (-not (Test-Path -Path $docSysConfigurationFilePath)) {
        Write-Output -ForegroundColor Red "DocSys Configuration file not found."
        Exit
    }

    $configurationFileName = Split-Path $docSysConfigurationFilePath -Leaf
    $configurationDirectory = Split-Path $docSysConfigurationFilePath -Parent

    $parts = $configurationFileName -split '\.'
    if($parts.count -eq 2) {
        $values = Get-Content $docSysConfigurationFilePath -Raw | ConvertFrom-Json -AsHashtable
    }
    elseif($parts.count -eq 3) {
        $rootFilePath = $configurationDirectory + '\' + $parts[0] + '.'  + $parts[2]

        if (-not (Test-Path -Path $rootFilePath)) {
            Write-Output -ForegroundColor Yellow "DocSys root Configuration file not found. Using regular configuration file."
            $values = Get-Content $docSysConfigurationFilePath -Raw | ConvertFrom-Json -AsHashtable
        }
        else {
            $root = Get-Content $rootFilePath -Raw | ConvertFrom-Json
            $override = Get-Content $docSysConfigurationFilePath -Raw | ConvertFrom-Json

            $json = Merge-JsonObject -Base $root -Override $override | Select-Object -Last 1 | ConvertTo-Json -Depth 10
            Write-Output "Merged configuration input"
            Write-Host $json
            $values = $json | ConvertFrom-Json -AsHashtable
        }
    }
    else {
        Throw "Only configurations filenames with 2 or 3 dots supported"
    }
    
    $secretpairs = $args[0]

    Write-Output $secretpairs

    foreach ($secretpair in $secretpairs.GetEnumerator()) {
        $key, $secret = $secretpair -split '=',2 
        Add-SecretsToDottedPath -Root $values -Path $key -Value $secret
    }

    Write-Output "Combined configuration input"
    Write-Host ($values | ConvertTo-JSON -Depth 100)

    Write-Output ""
    Write-Output "Starting configuration file generation"

    Get-ChildItem -Recurse -Include *.mustache -Name | ForEach-Object {
        $configuredFile = $_.Replace('.mustache','') 
        $template = Get-Content $_ | Out-String; ConvertFrom-MustacheTemplate -Template $template -Values $values | Tee-Object -Variable output
        if($configuredFile.EndsWith(".json") -And $reformatJsonOutput)
        {
            #Hacky fix to remove trailing comma's from mustache generated json arrays.
            $output | ConvertFrom-JsonNewtonsoft | ConvertTo-JsonNewtonsoft | Tee-Object -Variable output
        }

        $output | Out-File -FilePath $configuredFile -Encoding utf8
        Write-Output "Configurationfile $configuredFile created."
    }
}

function Add-SecretsToDottedPath {
    param (
        [hashtable]$Root,
        [string]$Path,
        [object]$Value
    )

    $parts = $Path -split '\.'
    $current = $Root

    for ($i = 0; $i -lt $parts.Length; $i++) {
        $key = $parts[$i]

        if ($i -eq $parts.Length - 1) {
            # Final element
            $current[$key] = $Value
        } else {
            if (-not $current.ContainsKey($key)) {
                $current[$key] = @{}
            }
            elseif (-not ($current[$key] -is [hashtable])) {
                throw "Path conflict at '$key' in '$Path'"
            }

            $current = $current[$key]
        }
    }
}

Format-ConfigurationFiles -docSysConfigurationFilePath $docSysConfigurationFilePath -reformatJsonOutput $reformatJsonOutput $args 