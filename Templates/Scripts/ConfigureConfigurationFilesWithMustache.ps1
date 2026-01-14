param ($docSysConfigurationFilePath)
Install-Module -Name PSMustache -Scope CurrentUser -Force

function Format-ConfigurationFiles {
    param ($docSysConfigurationFilePath)

    if (-not (Test-Path -Path $docSysConfigurationFilePath)) {
        Write-Output -ForegroundColor Red "DocSys Configuration file not found."
        Exit
    }
    
    $values = Get-Content $docSysConfigurationFilePath -Raw | ConvertFrom-Json -AsHashtable
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
        $template = Get-Content $_ | Out-String; ConvertFrom-MustacheTemplate -Template $template -Values $values | Out-File -FilePath $configuredFile -Encoding utf8
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

Format-ConfigurationFiles -docSysConfigurationFilePath $docSysConfigurationFilePath $args