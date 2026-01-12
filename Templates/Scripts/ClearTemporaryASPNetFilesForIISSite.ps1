param ($iisSiteName)
$temporaryASPNetFilesFolder = "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\Temporary ASP.NET Files\${iisSiteName}"
Write-Host "Clearing Temporary ASP.NET Files in directory: $temporaryASPNetFilesFolder"
if (Test-Path -Path $temporaryASPNetFilesFolder) {
    Remove-Item -Path $temporaryASPNetFilesFolder -Recurse
}