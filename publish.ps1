param(
    [Parameter(Mandatory)]
    [System.String]$Version,

    [Parameter(Mandatory)]
    [ValidateSet('Debug','Release')]
    [System.String]$Target,
    
    [Parameter(Mandatory)]
    [System.String]$TargetPath,
    
    [Parameter(Mandatory)]
    [System.String]$TargetAssembly,

    [Parameter(Mandatory)]
    [System.String]$RoundsPath,
    
    [Parameter(Mandatory)]
    [System.String]$ProjectPath
)

# Make sure Get-Location is the script path
Push-Location -Path (Split-Path -Parent $MyInvocation.MyCommand.Path)

# Test some preliminaries
("$TargetPath",
 "$RoundsPath",
 "$ProjectPath"
) | % {
    if (!(Test-Path "$_")) {Write-Error -ErrorAction Stop -Message "$_ folder is missing"}
}

# Go
Write-Host "Publishing for $Target from $TargetPath"

# Plugin name without ".dll"
$name = "$TargetAssembly" -Replace('.dll')

# Debug copies the dll to ROUNDS
if ($Target.Equals("Debug")) {
    Write-Host "Updating local installation in $RoundsPath"
    
    $plug = New-Item -Type Directory -Path "$RoundsPath\BepInEx\plugins\UnboundLib" -Force
    Write-Host "Copy $TargetAssembly to $plug"
    Copy-Item -Path "$TargetPath\$name.dll" -Destination "$plug" -Force
}

# Release package for ThunderStore
if($Target.Equals("Release") -and $name.Equals("UnboundLib")) {
    $package = "$ProjectPath\release"
    
    Write-Host "Packaging for ThunderStore"
    New-Item -Type Directory -Path "$package\Thunderstore" -Force
    $thunder = New-Item -Type Directory -Path "$package\Thunderstore\package"
    $thunder.CreateSubdirectory('plugins')
    Copy-Item -Path "$TargetPath\$name.dll" -Destination "$thunder\plugins\"
    Copy-Item -Path "$ProjectPath\README.md" -Destination "$thunder\README.md"
    Copy-Item -Path "$ProjectPath\manifest.json" -Destination "$thunder\manifest.json"

    ((Get-Content -path "$thunder\manifest.json" -Raw) -replace "#VERSION#", "$Version") | Set-Content -Path "$thunder\manifest.json"

    Remove-Item -Path "$package\Thunderstore\$name.$Version.zip" -Force
    Copy-Item -Path "$(Get-Location)\icon.png" -Destination "$thunder\icon.png"
    Compress-Archive -Path "$thunder\*" -DestinationPath "$package\Thunderstore\$name.$Version.zip"
    $thunder.Delete($true)
}

if($Target.Equals("Release")) {
    $package = "$ProjectPath\release"
    Copy-Item -Path "$TargetPath\$name.dll" -Destination "$package\$name.$Version.dll"
}

Pop-Location
