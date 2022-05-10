$env:PATH = ${env:ProgramFiles}+'\Microsoft Visual Studio\2022\Enterprise\MSBuild\Current\Bin' + ';' + $env:PATH

.\build.ps1 all
if(!$?) { Exit $LASTEXITCODE }