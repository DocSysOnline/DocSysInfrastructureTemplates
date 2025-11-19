param ($iisSiteName)
write-host $iisSiteName
$temporaryASPNetFilesFolder = "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\Temporary ASP.NET Files\${iisSiteName}"
write-host $temporaryASPNetFilesFolder
if (Test-Path -Path $temporaryASPNetFilesFolder) {
    "Path exists!"
} else {
    "Path doesn't exist."
}