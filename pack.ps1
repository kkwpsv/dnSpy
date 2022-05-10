$tempVersion = [Version](Select-String -Path DnSpyCommon.props "(?<=<DnSpyAssemblyVersion>).*(?=</DnSpyAssemblyVersion>)").Matches.Value

if (!$tempVersion) {
    Write-Output "Cannot find current version"
    exit -1
}

$currentVersion =New-Object -TypeName System.Version -ArgumentList ($tempVersion.Major,$tempVersion.Minor,$tempVersion.Build)

$maxOldVersion = ([Version[]](git tag) | Measure-Object -Maximum).Maximum

if ($maxOldVersion -and $currentVersion -le $maxOldVersion) {
    Write-Output "No need To release"
    exit 0
}

Write-Output "Do release"

$releaseObj =
@{
    "name"     = [string]$currentVersion;
    "tag_name" = [string]$currentVersion;
    "ref"      = $env:CI_BUILD_REF;
    "assets"   = @{"links" = [System.Collections.ArrayList]@() }
}

$fileName = "dnSpy-$currentVersion-netframework.7z"
7z a $fileName .\dnSpy\dnSpy\bin\Release\net48\*
Invoke-WebRequest -Method Post -Uri https://upload-z2.qiniup.com -Form @{"file" = (Get-item -Path $fileName); "key" = $fileName; "token" = $env:QiniuUploadToken }
$releaseObj.assets.links.Add(@{"name" = ".NET Framework"; "url" = "$env:QiniuReleaseUrl$fileName" })

$fileName = "dnSpy-$currentVersion-net-win32.7z"
7z a $fileName .\dnSpy\dnSpy\bin\Release\net5.0-windows\win-x86\publish\*
Invoke-WebRequest -Method Post -Uri https://upload-z2.qiniup.com -Form @{"file" = (Get-item -Path $fileName); "key" = $fileName; "token" = $env:QiniuUploadToken }
$releaseObj.assets.links.Add(@{"name" = ".NET x86"; "url" = "$env:QiniuReleaseUrl$fileName" })

$fileName = "dnSpy-$currentVersion-net-win64.7z"
7z a $fileName .\dnSpy\dnSpy\bin\Release\net5.0-windows\win-x64\publish\*
Invoke-WebRequest -Method Post -Uri https://upload-z2.qiniup.com -Form @{"file" = (Get-item -Path $fileName); "key" = $fileName; "token" = $env:QiniuUploadToken }
$releaseObj.assets.links.Add(@{"name" = ".NET x64"; "url" = "$env:QiniuReleaseUrl$fileName" })

Invoke-WebRequest -Method Post -Uri "$env:CI_API_V4_URL/projects/$env:CI_PROJECT_ID/releases" -ContentType "application/json" -Headers @{"JOB-TOKEN" = $env:CI_JOB_TOKEN } -Body (ConvertTo-Json -Depth 3 $releaseObj)
