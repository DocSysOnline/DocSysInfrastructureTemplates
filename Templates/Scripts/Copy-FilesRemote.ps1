param ($source, $targets, $accountType, $username, $password, $destination, $cleanTargetBeforeCopy)

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

$files = Get-Item -Path $source

$sourcedirectory = Get-Item -Path $source
$sourcepath = $sourcedirectory.FullName.TrimEnd('\')

Write-Debug "Source path is $sourcepath"

if (-not $destination.EndsWith('\')) {
    $destination = $destination + '\'
}

Write-Debug "Destination is $destination"

$serverList = @()
$targets.split(',', [System.StringSplitOptions]::RemoveEmptyEntries) | ForEach-Object { if( ![string]::IsNullOrWhiteSpace($_) -and ![string]::Equals('\n', $_)) { $serverList += $_ } }

foreach($server in $serverList) {
    Write-Host "Starting copy to server $server"

    if ($credential) {
		Write-Host "Creating session to '$server' for '$username'."
        $session = New-PSSession -ComputerName $server -Credential $credential
    }
    else
    {
		Write-Host "Creating session to '$server' for '$($env:USERDOMAIN)\$($env:USERNAME)'."
		$session = New-PSSession -ComputerName $Server
    }

    if ($cleanTargetBeforeCopy) {
        Write-Debug "Removing folder $destination on target machine"

        Invoke-Command -Session $session -ScriptBlock { 
            param($p)
            if (Test-Path $p) {
                Remove-Item -Path $p -Recurse -Force
            }
        } -ArgumentList $destination
    }

    Write-Debug "Ensuring destination folder exists on target machine"

    Invoke-Command -Session $session -ScriptBlock { 
        param($p)
        New-Item -Path $p -ItemType Directory -Force | Out-Null
    } -ArgumentList $destination

    Copy-Item -Path $source -Destination $targetpath -ToSession $session -Force -Recurse
    Write-Host "Finished copy to server $server"
}