<#
.SYNOPSIS
  Build this workspace's release archives from Spriggit YAML + committed .pex.

.DESCRIPTION
  Data-driven by build/manifest.json - the script contains no mod-specific names.

  Source vs. derived:
    build/releases/<release>/fomod/   COMMITTED source (the installer XML + any images)
    build/staging/<release>/          fully DERIVED, gitignored, wiped and rebuilt every run
    build/dist/<archiveName>.7z       DERIVED, gitignored

  For each release:
    1. wipes build/staging/<release>/ and copies build/releases/<release>/fomod/ into it
       (a release with "fomod": false skips that and ships a plain archive)
    2. deserializes each plugin's YAML -> <release>/<dest>.esp via the Spriggit CLI
    3. copies the release's committed compiled .pex into its Scripts/ folder
    4. compresses build/staging/<release>/ -> build/dist/<archiveName>.7z

  Runs both locally (Spriggit CLI path auto-resolved from .claude/config/tools.json) and in
  GitHub Actions (pass -SpriggitCli explicitly). It never invokes the Papyrus compiler - the
  .pex are expected to be committed and current (recompile + commit when a .psc changes).

  Windows PowerShell 5.1 and PowerShell 7 both run this script.

.PARAMETER SpriggitCli
  Path to Spriggit.CLI.exe. Defaults to $Tools.spriggitCli from tools.json when available.

.PARAMETER FomodDir
  Root of the committed FOMOD sources, one folder per release name. Default build/releases.

.PARAMETER CheckFomod
  Only verify manifest <-> fomod/ModuleConfig.xml parity, then exit (no build).
#>
[CmdletBinding()]
param(
    [string]$SpriggitCli,
    [string]$FomodDir    = 'build/releases',
    [string]$OutDir      = 'build/staging',
    [string]$ArchiveDir  = 'build/dist',
    [switch]$CheckFomod
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$RepoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $RepoRoot

function Resolve-SpriggitCli {
    param([string]$Explicit)
    if ($Explicit) {
        if (-not (Test-Path $Explicit)) { throw "Spriggit CLI not found at: $Explicit" }
        return $Explicit
    }
    $toolsPs1 = Join-Path $RepoRoot '.claude/config/tools.ps1'
    if (Test-Path $toolsPs1) {
        . $toolsPs1
        if ($Tools.spriggitCli -and (Test-Path $Tools.spriggitCli)) { return $Tools.spriggitCli }
    }
    throw "Spriggit CLI path not supplied and not resolvable from tools.json. Pass -SpriggitCli <path>."
}

function Resolve-SevenZip {
    $cmd = Get-Command '7z' -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    $candidates = @(
        'C:\Program Files\7-Zip\7z.exe',
        'C:\Program Files (x86)\7-Zip\7z.exe'
    )
    foreach ($c in $candidates) { if (Test-Path $c) { return $c } }
    throw "7z.exe not found (needed for archiving). Install 7-Zip or add it to PATH."
}

function Format-Size {
    param([long]$Bytes)
    if ($Bytes -ge 1MB) { return ('{0:N2} MB' -f ($Bytes / 1MB)) }
    if ($Bytes -ge 1KB) { return ('{0:N1} KB' -f ($Bytes / 1KB)) }
    return "$Bytes B"
}

# ---- Load manifest ---------------------------------------------------------
$manifestPath = Join-Path $PSScriptRoot 'manifest.json'
$manifest = Get-Content $manifestPath -Raw | ConvertFrom-Json

function Test-ReleaseWantsFomod {
    param($Release)
    if ($Release.PSObject.Properties.Name -contains 'fomod') { return [bool]$Release.fomod }
    return $true
}

function Get-ReleaseFomodSource {
    param($Release)
    # Committed installer source for a release: build/releases/<release name>/fomod/
    return (Join-Path (Join-Path $RepoRoot $FomodDir) (Join-Path $Release.name 'fomod'))
}

function Get-ReleaseScriptSets {
    param($Owner)
    # 'scripts' may be a single {from,to} object or an array of them, at release *or* plugin level.
    # Each entry copies build artifacts into the staging tree; 'from' is either a folder (all files
    # matching 'pattern', default *.pex) or a single file. Normalising here keeps the two call sites
    # identical and lets a release ship more than one kind of artifact (e.g. Scripts/ + SKSE/).
    if ($Owner.PSObject.Properties.Name -notcontains 'scripts' -or -not $Owner.scripts) { return @() }
    return @($Owner.scripts)
}

function Copy-ScriptSet {
    param($Set, [string]$StageDir, [string]$Label)
    # Copies one manifest 'scripts' entry into the staging tree and returns the file names copied.
    # An empty or missing source is fatal: the archive would otherwise ship silently script-less,
    # which only shows up as "the mod does nothing" hours later in-game.
    $from    = Join-Path $RepoRoot $Set.from
    $pattern = '*.pex'
    if ($Set.PSObject.Properties.Name -contains 'pattern' -and $Set.pattern) { $pattern = $Set.pattern }
    if (-not (Test-Path $from)) {
        throw "Build artifact missing: $from. Recompile (.psc -> .pex) and commit it (see README 'CI build & release')."
    }
    $dst = Join-Path $StageDir $Set.to
    New-Item -ItemType Directory -Force $dst | Out-Null

    if (Test-Path $from -PathType Leaf) {
        Copy-Item $from $dst -Force
        Write-Host "$Label script $(Split-Path -Leaf $from) -> $($Set.to)/"
        return @(Split-Path -Leaf $from)
    }

    $files = @(Get-ChildItem $from -Filter $pattern -File -ErrorAction SilentlyContinue)
    if ($files.Count -eq 0) {
        throw "No files matching '$pattern' in $from. Recompile and commit them before building."
    }
    Copy-Item (Join-Path $from $pattern) $dst -Force
    Write-Host "$Label copied $($files.Count) $pattern -> $($Set.to)/"
    return @($files.Name)
}

# ---- Manifest sanity -------------------------------------------------------
# Cheap checks that turn a silently wrong archive into an up-front failure.
$seenArchives = @{}
foreach ($rel in $manifest.releases) {
    if (-not $rel.name)        { throw "manifest.json: a release has no 'name'." }
    if (-not $rel.archiveName) { throw "manifest.json: release '$($rel.name)' has no 'archiveName'." }
    if ($seenArchives.ContainsKey($rel.archiveName)) {
        throw "manifest.json: two releases share archiveName '$($rel.archiveName)' - the second would overwrite the first."
    }
    $seenArchives[$rel.archiveName] = $true

    $seenDests = @{}
    foreach ($p in $rel.plugins) {
        if (-not $p.yamlSource) { throw "manifest.json: a plugin in '$($rel.name)' has no 'yamlSource'." }
        if (-not $p.dest)       { throw "manifest.json: '$($p.yamlSource)' has no 'dest'." }
        if ($seenDests.ContainsKey($p.dest)) {
            throw "manifest.json: release '$($rel.name)' builds '$($p.dest)' twice."
        }
        $seenDests[$p.dest] = $true
        $src = Join-Path $RepoRoot $p.yamlSource
        if (-not (Test-Path $src)) { throw "manifest.json: yamlSource does not exist: $($p.yamlSource)" }
    }
}

# ---- FOMOD parity check ----------------------------------------------------
function Get-JpegEncoding {
    param([string]$Path)
    # Returns 'baseline' | 'progressive' | 'unknown', or $null when the file is not a JPEG.
    # Walks the marker segments rather than grepping for FFC2: every marker ahead of the SOS
    # entropy-coded data carries its own length, so we can step over payloads exactly. A naive
    # byte search would false-positive on compressed scan data that happens to contain FF C2.
    try { $bytes = [System.IO.File]::ReadAllBytes($Path) } catch { return $null }
    if ($bytes.Length -lt 4) { return $null }
    if ($bytes[0] -ne 0xFF -or $bytes[1] -ne 0xD8) { return $null }   # no SOI => not a JPEG
    $i = 2
    while ($i -lt $bytes.Length - 1) {
        if ($bytes[$i] -ne 0xFF) { return 'unknown' }
        $marker = $bytes[$i + 1]
        if ($marker -eq 0xFF) { $i++; continue }                                    # fill byte
        if ($marker -ge 0xD0 -and $marker -le 0xD9) { $i += 2; continue }           # standalone
        if ($marker -eq 0xDA) { return 'unknown' }                                  # reached scan data
        if ($marker -eq 0xC0 -or $marker -eq 0xC1) { return 'baseline' }            # SOF0 / SOF1
        if ($marker -eq 0xC2) { return 'progressive' }                              # SOF2
        if ($i + 3 -ge $bytes.Length) { return 'unknown' }
        $len = ($bytes[$i + 2] -shl 8) -bor $bytes[$i + 3]
        if ($len -lt 2) { return 'unknown' }
        $i += 2 + $len
    }
    return 'unknown'
}

function Test-FomodParity {
    $ok = $true
    foreach ($rel in $manifest.releases) {
        # A release may opt out of a FOMOD entirely with "fomod": false - there is nothing to check.
        if (-not (Test-ReleaseWantsFomod $rel)) { continue }
        $fomodSrc = Get-ReleaseFomodSource $rel
        $fomod    = Join-Path $fomodSrc 'ModuleConfig.xml'
        if (-not (Test-Path $fomod)) {
            Write-Host "  [NO MODULECONFIG] $($rel.name): expected $fomod" -ForegroundColor Red
            $ok = $false
            continue
        }
        [xml]$xml = Get-Content $fomod -Raw
        $fomodEsps = $xml.SelectNodes('//file') |
            ForEach-Object { $_.source } |
            Where-Object { $_ -and $_.ToLower().EndsWith('.esp') } |
            ForEach-Object { $_.Replace('\','/') } | Sort-Object -Unique
        $manifestDests = @($rel.plugins | ForEach-Object { $_.dest.Replace('\','/') })
        foreach ($f in $fomodEsps) {
            if ($manifestDests -notcontains $f) {
                Write-Host "  [MISSING IN MANIFEST] $($rel.name): fomod references '$f'" -ForegroundColor Red
                $ok = $false
            }
        }
        # A plugin the manifest builds but the FOMOD never installs is usually an oversight (a patch
        # added to the manifest and forgotten in ModuleConfig.xml). It is only a warning, because a
        # release may legitimately stage a plugin that its installer references indirectly - set
        # "allowUnreferencedPlugins": true on the release to silence it.
        $allowUnreferenced = $false
        if ($rel.PSObject.Properties.Name -contains 'allowUnreferencedPlugins') {
            $allowUnreferenced = [bool]$rel.allowUnreferencedPlugins
        }
        if (-not $allowUnreferenced) {
            foreach ($d in $manifestDests) {
                if ($fomodEsps -notcontains $d) {
                    Write-Host "  [NOT IN FOMOD] $($rel.name): manifest builds '$d' but fomod never installs it" -ForegroundColor Yellow
                }
            }
        }

        # Installer images. A bad image reference breaks nothing detectable: the archive builds, the
        # wizard opens, and MO2 just renders a blank banner - so it costs a full install cycle to
        # notice. Both failure modes below have actually shipped from this repo. The rest of the
        # recipe (needing an <installSteps> block at all) is in CLAUDE.md under
        # "FOMOD images that actually render in MO2".
        # Images resolve against the release's ARCHIVE ROOT - which in the committed source tree is
        # build/releases/<name>/ (the folder that becomes the root of the .7z).
        $archiveRoot = Split-Path -Parent $fomodSrc
        $imageNodes = @($xml.SelectNodes('//moduleImage')) + @($xml.SelectNodes('//image'))
        # Distinct paths only: one image is typically referenced by both <moduleImage> and every
        # plugin's <image>, and repeating an identical complaint per node buries the real list.
        $imagePaths = @($imageNodes | ForEach-Object { $_.GetAttribute('path') } |
            Where-Object { $_ } | Sort-Object -Unique)
        foreach ($imgPath in $imagePaths) {
            # path= is relative to the ARCHIVE ROOT, so it must carry the "fomod/" prefix itself.
            $relPath = $imgPath.Replace('\', '/').TrimStart('/')
            $abs = Join-Path $archiveRoot $relPath
            if (-not (Test-Path $abs)) {
                Write-Host "  [IMAGE NOT FOUND] $($rel.name): path=`"$imgPath`" resolves to nothing" -ForegroundColor Red
                # The overwhelmingly likely cause: the "fomod/" prefix was omitted, because the path
                # looks right sitting inside fomod/ModuleConfig.xml. Say so instead of just failing.
                if (Test-Path (Join-Path $fomodSrc $relPath)) {
                    Write-Host "                   -> did you mean `"fomod\$($relPath.Replace('/','\'))`"? path= is relative to the archive root, not to fomod/." -ForegroundColor Red
                }
                $ok = $false
                continue
            }
            # No separator check here. The template this build script came from asserted that only
            # backslashes render in MO2, but the installers shipped since v2.0.0 use forward slashes
            # throughout and render fine - so the claim is unfounded and warning on it would flag 15
            # working images every build. What actually breaks an image is the path not resolving
            # (usually a missing "fomod/" prefix), which the check above catches.
            # Progressive JPEG: reported, but NOT a build failure. The template this script came from
            # treated it as fatal, claiming MO2 renders such images blank - but every installer image
            # shipped in v2.0.0/v2.0.1 is progressive, and MO2 renders through Qt, which reads
            # progressive JPEG. The claim has never been verified against this mod. If an image ever
            # does come up blank in the wizard, re-encoding it as baseline (or PNG) is the fix.
            if ((Get-JpegEncoding $abs) -eq 'progressive') {
                Write-Host "  [PROGRESSIVE JPEG] $($rel.name): '$imgPath' - fine in MO2 as far as we know; re-encode as baseline if it ever renders blank" -ForegroundColor DarkGray
            }
        }
    }
    return $ok
}

if ($CheckFomod) {
    Write-Host "Checking manifest <-> FOMOD parity..." -ForegroundColor Cyan
    if (Test-FomodParity) { Write-Host "FOMOD parity OK." -ForegroundColor Green; exit 0 }
    else { Write-Error "FOMOD parity check failed."; exit 1 }
}

# ---- Build -----------------------------------------------------------------
$spriggit = Resolve-SpriggitCli -Explicit $SpriggitCli
$sevenZip = Resolve-SevenZip
Write-Host "Spriggit CLI : $spriggit"
Write-Host "7-Zip        : $sevenZip"

$stagingAbs = Join-Path $RepoRoot $OutDir
$distAbs    = Join-Path $RepoRoot $ArchiveDir
New-Item -ItemType Directory -Force $stagingAbs | Out-Null
Remove-Item $distAbs -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force $distAbs    | Out-Null

# Collected only to print the closing summary below - nothing is written to disk.
$builtArchives = @()

foreach ($rel in $manifest.releases) {
    Write-Host "`n=== Release: $($rel.name) ===" -ForegroundColor Cyan
    $stageDir = Join-Path $stagingAbs $rel.name

    # 1. rebuild the stage dir from scratch. Everything in build/staging/ is derived, so wiping it
    #    is what guarantees a renamed dest, a deleted patch or a removed .pex cannot survive into
    #    the new archive as a leftover file.
    Remove-Item $stageDir -Recurse -Force -ErrorAction SilentlyContinue
    New-Item -ItemType Directory -Force $stageDir | Out-Null

    #    Copy in the committed installer source. A release may opt out with "fomod": false and ship
    #    a plain archive instead - the right shape whenever the install has nothing to ask (a single
    #    .esp with no options).
    $wantsFomod = Test-ReleaseWantsFomod $rel
    $fomodSrc   = Get-ReleaseFomodSource $rel
    if ($wantsFomod) {
        if (-not (Test-Path (Join-Path $fomodSrc 'ModuleConfig.xml'))) {
            throw "Missing committed FOMOD for '$($rel.name)': expected $fomodSrc\ModuleConfig.xml (or set `"fomod`": false on the release)"
        }
        Copy-Item $fomodSrc (Join-Path $stageDir 'fomod') -Recurse -Force
        Write-Host "  fomod  <- $FomodDir/$($rel.name)/fomod"
    }
    elseif (Test-Path $fomodSrc) {
        throw "'$($rel.name)' sets fomod: false but $fomodSrc still exists - delete it"
    }

    # 2. deserialize each plugin
    foreach ($p in $rel.plugins) {
        $yamlSrc = Join-Path $RepoRoot $p.yamlSource
        $meta    = Join-Path $yamlSrc 'spriggit-meta.json'
        if (-not (Test-Path $meta)) { throw "Not a Spriggit YAML folder (no spriggit-meta.json): $yamlSrc" }
        $outEsp  = Join-Path $stageDir $p.dest
        New-Item -ItemType Directory -Force (Split-Path -Parent $outEsp) | Out-Null

        Write-Host "  deserialize $($p.yamlSource) -> $($p.dest)"
        & $spriggit deserialize --InputPath $yamlSrc --OutputPath $outEsp
        if ($LASTEXITCODE -ne 0) { throw "Spriggit deserialize failed for $($p.yamlSource) (exit $LASTEXITCODE)" }
        if (-not (Test-Path $outEsp)) { throw "Spriggit produced no output at $outEsp" }

        # optional per-plugin scripts (a patch that ships its own committed .pex)
        foreach ($s in (Get-ReleaseScriptSets $p)) {
            $null = Copy-ScriptSet -Set $s -StageDir $stageDir -Label "    +"
        }
    }

    # 3. copy the release's committed build artifacts (the addon's compiled .pex)
    foreach ($s in (Get-ReleaseScriptSets $rel)) {
        $null = Copy-ScriptSet -Set $s -StageDir $stageDir -Label "  "
    }

    # 4. archive
    $archivePath = Join-Path $distAbs ("{0}.7z" -f $rel.archiveName)
    Remove-Item $archivePath -Force -ErrorAction SilentlyContinue
    Write-Host "  archiving -> $($rel.archiveName).7z"
    Push-Location $stageDir
    try {
        & $sevenZip a -t7z -mx=9 -bso0 -bsp0 $archivePath '*' | Out-Null
        if ($LASTEXITCODE -ne 0) { throw "7z failed for $($rel.name) (exit $LASTEXITCODE)" }
    } finally { Pop-Location }

    $fi = Get-Item $archivePath
    $builtArchives += [pscustomobject]@{
        Name   = $fi.Name
        Bytes  = $fi.Length
        Sha256 = (Get-FileHash $archivePath -Algorithm SHA256).Hash
    }
}

Write-Host "`nArchives:" -ForegroundColor Cyan
foreach ($a in $builtArchives) {
    Write-Host ("  {0}  {1}  {2}" -f $a.Name, (Format-Size $a.Bytes), $a.Sha256.ToLower())
}
Write-Host "`nBuild complete. Archives in $ArchiveDir." -ForegroundColor Green
