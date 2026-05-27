param(
    [string]$OutputPath = (Join-Path $PSScriptRoot '..\dist\mcpserver-cowork-plugin.zip')
)

$ErrorActionPreference = 'Stop'
$root = Resolve-Path (Join-Path $PSScriptRoot '..')
$dist = Split-Path -Parent $OutputPath

Push-Location $root
try {
    node .\scripts\validate-plugin.js

    if (-not (Test-Path $dist)) {
        New-Item -ItemType Directory -Path $dist | Out-Null
    }

    if (Test-Path $OutputPath) {
        Remove-Item -LiteralPath $OutputPath -Force
    }

    $items = @(
        '.claude-plugin',
        '.mcp.json',
        'bin',
        'hooks',
        'lib',
        'skills',
        'docs',
        'LICENSE',
        'README.md'
    )

    Compress-Archive -Path $items -DestinationPath $OutputPath -Force
    Write-Output "Wrote $OutputPath"
}
finally {
    Pop-Location
}
