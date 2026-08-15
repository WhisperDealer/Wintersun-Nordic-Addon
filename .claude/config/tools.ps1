# Dot-source from the repo root to load workspace tool paths:
#     . ".claude/config/tools.ps1"
#     & $Tools.spriggitCli serialize ...
#
# Reads .claude/config/tools.json (machine-specific, gitignored). Falls back to
# tools.example.json so a fresh clone still resolves. Create tools.json by copying
# tools.example.json and filling in this machine's paths (see README, "First-run setup").

$cfgDir = Split-Path -Parent $PSCommandPath
$cfgPath = Join-Path $cfgDir 'tools.json'
if (-not (Test-Path $cfgPath)) {
    $cfgPath = Join-Path $cfgDir 'tools.example.json'
    Write-Warning "tools.json not found; using tools.example.json. Copy tools.example.json to tools.json and fill in your paths."
}
$Tools = Get-Content -Raw -LiteralPath $cfgPath | ConvertFrom-Json

# Verify the tools an operation needs before relying on them. Usage:
#     Assert-Tool $Tools.papyrusCompiler 'papyrusCompiler'
function Assert-Tool {
    param([string]$Path, [string]$Name)
    if ([string]::IsNullOrWhiteSpace($Path)) {
        throw "Config key '$Name' is empty in $cfgPath. Set it and retry."
    }
    if (-not (Test-Path -LiteralPath $Path)) {
        throw "'$Name' points at a missing path: $Path  (config: $cfgPath)"
    }
    return $Path
}
