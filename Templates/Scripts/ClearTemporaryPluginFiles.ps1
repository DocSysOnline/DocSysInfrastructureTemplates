$temporaryPluginFilesFolder = "C:\Windows\Temp\DSO\DSO-Plugins"
Write-Host "Clearing temporary plugin files in directory: $temporaryPluginFilesFolder"

for ($i = 1; $i -le 3; $i++) {
    if ((Test-Path -Path $temporaryPluginFilesFolder) -eq $false) {
        break
    }
    try
    {
        Remove-Item -Path $temporaryPluginFilesFolder -Recurse
        Write-Output "Clearing temporary plugin files attempt: $i"
    }
    catch { }
}
