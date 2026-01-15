param ($iisSiteName)
$temporaryASPNetFilesFolder = "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\Temporary ASP.NET Files\${iisSiteName}"
Write-Host "Clearing Temporary ASP.NET Files in directory: $temporaryASPNetFilesFolder"

for ($i = 1; $i -le 3; $i++) {
    if ((Test-Path -Path $temporaryASPNetFilesFolder) -eq $false) {
        break
    }
    try
    {
        Remove-Item -Path $temporaryASPNetFilesFolder -Recurse
        Write-Output "Clearing temporary files attempt: $i"
    }
    catch { }
}
