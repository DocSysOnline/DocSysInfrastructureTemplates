param ($servers, $accountType, $username, $password, $scriptType, $inlineScript, $scriptPath, $scriptArguments)

$ErrorActionPreference = "Stop"

if ($AccountType -eq 'UserAccount') {
    if (-not $username -or -not $password) {
        throw "Username and/or password missing."
    }
    Write-Debug "Creating credential object for $username"

    Write-Host "Creating credential object for user '$username'."
    $securepassword = ConvertTo-SecureString -String $password -AsPlainText -Force
    $credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ($username, $securepassword)
}

$serverList = @()
$servers.split(',', [System.StringSplitOptions]::RemoveEmptyEntries) | ForEach-Object { if( ![string]::IsNullOrWhiteSpace($_) -and ![string]::Equals('\n', $_)) { $serverList += $_ } }

foreach($server in $serverList) {
    Write-Host "Login to server $server"

    if ($credential) {
        Write-Host "Creating session to '$server' for '$username'."
        $session = New-PSSession -ComputerName $server -Credential $credential
    }
    else {
        Write-Host "Creating session to '$server' for '$($env:USERDOMAIN)\$($env:USERNAME)'."
        $session = New-PSSession -ComputerName $Server
    }
    try {
        if($scriptType -eq 'Inline')
        {
            $singleLineInlineScript = $inlineScript.Replace('`r`n',';').Replace('`n`r',';').Replace('`n',';').Replace('`r',';')
            Write-Host "Execute: '$singleLineInlineScript'"

            Invoke-Command –Session $session –ScriptBlock { ($singleLineInlineScript)} -ArgumentList $scriptArguments
        }
        if($scriptType -eq 'FilePath')
        {
            Write-Host $scriptPath

            Invoke-Command –Session $session -FilePath $scriptPath  -ArgumentList $scriptArguments
        }
    }
    catch {
        Write-Host "An error occurred:"
        Write-Host $_
    }
    finally {
        if ($session) {
            Remove-PSSession $session
        }
    }
}

if ($error[0]) {
    Write-Warning "Finished deploying with errors"
    $error[0]
}
else {
    Write-Host "Finished deploying"
}