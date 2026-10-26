param ($docSysConfigurationFilePath, $reformatJsonOutput = $true)

$availableModules = Get-Module PSMustache -ListAvailable
if ($null -eq $availableModules)
{
    Import-Module $PSScriptRoot\PSMustache.psm1
}

$availableModules = Get-Module newtonsoft.json -ListAvailable
if ($null -eq $availableModules)
{
    Import-Module $PSScriptRoot\newtonsoft.json.psm1
}

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
    param ($docSysConfigurationFilePath, $reformatJsonOutput = $true)

    if ([string]::IsNullOrWhiteSpace($docSysConfigurationFilePath) -or -not (Test-Path -Path $docSysConfigurationFilePath)) {
        Write-Host -ForegroundColor Red "DocSys Configuration file not found."
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
            Write-Host -ForegroundColor Yellow "DocSys root Configuration file not found. Using regular configuration file."
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
    
    $rawSecrets = @($args)
    $secretpairs = @()
    if ($reformatJsonOutput -is [string] -and $reformatJsonOutput -match '=') {
        $secretpairs += $reformatJsonOutput
        $reformatJsonOutput = $true
    }
    foreach ($item in $rawSecrets) {
        if ($item -is [System.Collections.IEnumerable] -and $item -isnot [string]) {
            foreach ($subItem in $item) {
                if ($null -ne $subItem) { $secretpairs += $subItem }
            }
        }
        elseif ($null -ne $item) {
            $secretpairs += $item
        }
    }

    Write-Output $secretpairs

    if ($null -ne $secretpairs) {
        foreach ($secretpair in $secretpairs) {
            if (-not [string]::IsNullOrWhiteSpace($secretpair)) {
                $key, $secret = $secretpair -split '=',2 
                Add-SecretsToDottedPath -Root $values -Path $key -Value $secret
            }
        }
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
            Write-Output "Repairing malformed json"

            #Hacky fix to remove trailing comma's from mustache generated json arrays.
            $output | ConvertFrom-JsonNewtonsoft | ConvertTo-JsonNewtonsoft | Tee-Object -Variable output
        }

        $output | Out-File -FilePath $configuredFile -Encoding utf8
        Write-Output "Configurationfile $configuredFile created."
    }
}

function Find-KeyInDictionary ([System.Collections.IDictionary]$dict, [string]$targetKey) {
    if ($dict.Contains($targetKey)) { return $targetKey }
    foreach ($k in $dict.Keys) {
        if ([string]::Equals($k.ToString(), $targetKey, [System.StringComparison]::OrdinalIgnoreCase)) {
            return $k
        }
    }
    return $null
}

function Find-ChildDictionaryWithKey ([System.Collections.IDictionary]$dict, [string]$targetKey) {
    foreach ($k in $dict.Keys) {
        $val = $dict[$k]
        if ($val -is [System.Collections.IDictionary]) {
            $matchedKey = Find-KeyInDictionary -dict $val -targetKey $targetKey
            if ($null -ne $matchedKey) {
                return @{ Dict = $val; Key = $matchedKey }
            }
        }
    }
    return $null
}

function Add-SecretsToDottedPath {
    param (
        [System.Collections.IDictionary]$Root,
        [string]$Path,
        [object]$Value
    )

    if ($null -eq $Root -or [string]::IsNullOrWhiteSpace($Path)) {
        return
    }

    if ($Value -is [string]) {
        $Value = $Value.Trim()
        if (($Value.StartsWith('"') -and $Value.EndsWith('"')) -or ($Value.StartsWith("'") -and $Value.EndsWith("'"))) {
            if ($Value.Length -ge 2) {
                $Value = $Value.Substring(1, $Value.Length - 2)
            }
        }
    }

    $normalizedPath = $Path -replace '\[', '.['
    $parts = $normalizedPath.Split('.', [System.StringSplitOptions]::RemoveEmptyEntries)

    $current = $Root
    $startIndex = 0

    if ($parts.Length -gt 1) {
        $firstMatched = Find-KeyInDictionary -dict $current -targetKey $parts[0]
        $secondMatched = Find-KeyInDictionary -dict $current -targetKey $parts[1]
        if ($null -eq $firstMatched -and $null -ne $secondMatched) {
            $startIndex = 1
        }
    }

    if ($startIndex -eq 0 -and $parts.Length -gt 0) {
        $firstMatched = Find-KeyInDictionary -dict $current -targetKey $parts[0]
        if ($null -eq $firstMatched) {
            $damKey = Find-KeyInDictionary -dict $current -targetKey 'DAM'
            if ($null -ne $damKey -and $current[$damKey] -is [System.Collections.IDictionary]) {
                $damMatched = Find-KeyInDictionary -dict $current[$damKey] -targetKey $parts[0]
                if ($null -ne $damMatched) {
                    $current = $current[$damKey]
                }
            }
        }
    }

    for ($i = $startIndex; $i -lt $parts.Length; $i++) {
        $part = $parts[$i]
        $isLast = ($i -eq $parts.Length - 1)

        if ($current -is [System.Collections.IList] -or $current -is [System.Array]) {
            $index = -1
            if ($part -match '^\[?(\d+)\]?$') {
                $index = [int]$Matches[1]
            }
            elseif ($part -match '^\[?(?:Id|id|Name|name)=([^\]]+)\]?$') {
                $identifier = $Matches[1]
                for ($idx = 0; $idx -lt $current.Count; $idx++) {
                    $item = $current[$idx]
                    if ($item -is [System.Collections.IDictionary]) {
                        $idKey = Find-KeyInDictionary -dict $item -targetKey 'Id'
                        if (-not $idKey) { $idKey = Find-KeyInDictionary -dict $item -targetKey 'Name' }
                        if ($idKey -and [string]::Equals($item[$idKey].ToString(), $identifier, [System.StringComparison]::OrdinalIgnoreCase)) {
                            $index = $idx
                            break
                        }
                    }
                }
                if ($index -lt 0) {
                    throw "Array item with identifier '$identifier' not found in '$Path'"
                }
            }
            else {
                for ($idx = 0; $idx -lt $current.Count; $idx++) {
                    $item = $current[$idx]
                    if ($item -is [System.Collections.IDictionary]) {
                        $idKey = Find-KeyInDictionary -dict $item -targetKey 'Id'
                        if (-not $idKey) { $idKey = Find-KeyInDictionary -dict $item -targetKey 'Name' }
                        if ($idKey -and [string]::Equals($item[$idKey].ToString(), $part, [System.StringComparison]::OrdinalIgnoreCase)) {
                            $index = $idx
                            break
                        }
                    }
                }
                if ($index -lt 0) {
                    throw "Expected array index or identifier at '$part' in '$Path'"
                }
            }

            if ($index -lt 0 -or $index -ge $current.Count) {
                throw "Index $index out of range for array at '$part' in '$Path'"
            }

            if ($isLast) {
                $current[$index] = $Value
            }
            else {
                $current = $current[$index]
            }
        }
        elseif ($current -is [System.Collections.IDictionary]) {
            $targetKey = $part
            if ($part -match '^\[(\d+)\]$') {
                $targetKey = $Matches[1]
            }

            $matchedKey = Find-KeyInDictionary -dict $current -targetKey $targetKey

            if ($isLast) {
                if ($null -ne $matchedKey) {
                    $current[$matchedKey] = $Value
                }
                else {
                    $childMatch = Find-ChildDictionaryWithKey -dict $current -targetKey $targetKey
                    if ($null -ne $childMatch) {
                        $childMatch.Dict[$childMatch.Key] = $Value
                    }
                    else {
                        $current[$targetKey] = $Value
                    }
                }
            }
            else {
                if ($null -eq $matchedKey) {
                    $childMatch = Find-ChildDictionaryWithKey -dict $current -targetKey $targetKey
                    if ($null -ne $childMatch) {
                        $current = $childMatch.Dict
                        $matchedKey = $childMatch.Key
                    }
                    else {
                        $nextPart = $parts[$i + 1]
                        if ($nextPart -match '^\[?\d+\]?$') {
                            $current[$targetKey] = @()
                        }
                        else {
                            $current[$targetKey] = [ordered]@{}
                        }
                        $matchedKey = $targetKey
                        $current = $current[$matchedKey]
                    }
                }
                else {
                    $current = $current[$matchedKey]
                }
            }
        }
        else {
            throw "Path conflict: cannot traverse into object of type $($current.GetType().FullName) at '$part' in '$Path'"
        }
    }
}

$scriptSecrets = @()
if ($reformatJsonOutput -is [string] -and $reformatJsonOutput -match '=') {
    $scriptSecrets += $reformatJsonOutput
    $reformatJsonOutput = $true
}
if ($args) {
    $scriptSecrets += $args
}

Format-ConfigurationFiles -docSysConfigurationFilePath $docSysConfigurationFilePath -reformatJsonOutput $reformatJsonOutput $scriptSecrets