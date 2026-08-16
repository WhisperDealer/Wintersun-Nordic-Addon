# Wintersun Nordic Addon

Extends **[Wintersun – Faiths of Skyrim](https://www.nexusmods.com/skyrimspecialedition/mods/22506)**
(Enai Siaion) with the Nordic pantheon — **Kyne, Jhunal, Stuhn, Tsun, Orkey, the Nordic aspects of
Mara and Dibella, and Alduin** — each with its own tenets, blessing, boons, devotee effects and
shrine map markers, plus a collection of compatibility patches for popular settlement, temple and
religion mods.

The mod is **authored as text**: every plugin lives in this repo as
[Spriggit](https://github.com/Mutagen-Modding/Spriggit) YAML and is re-packed to an `.esp` by the
build. **You edit the YAML, never the binary plugin.**

- **Game:** Skyrim Special Edition
- **Requires:** Wintersun – Faiths of Skyrim
- **Main plugin:** `WintersunNordicDivines.esp` (ESL / `Small`-flagged)
- **Spriggit package / version:** `Spriggit.Yaml.Skyrim` `0.40.0` (pinned in [`.spriggit`](.spriggit))
- **Tool paths:** resolved from `.claude/config/tools.json` (gitignored, per-machine) — **no
  hardcoded paths anywhere in the skills or the build.**

See [`CLAUDE.md`](CLAUDE.md) for the deity index map, the per-deity record templates, the
parallel-array invariants of Wintersun's tracker quest, and the Wintersun-specific gotchas.

## What gets built

Two installable archives, both produced by one command:

| Archive | Contents |
|---|---|
| `Wintersun - Nordic Addon.7z` | `WintersunNordicDivines.esp` + 18 compiled scripts, plus the optional `WintersunNordicAddonTribunalPatch.esp` (FOMOD-selectable) |
| `Wintersun - Nordic Addon (Patch Collection).7z` | 18 optional compatibility patches, one FOMOD checkbox each |

Patches cover: Amber Guard · Ancient Nordic Temple · Berserkyr · Capital Windhelm Expansion ·
Children of the Sky · Granite Hill · Skyrim's Got Talent · Shrine to Kyne · Stave Churches 2024
(AIO + Dawnstar / Ivarstead / Windhelm) · The Great City of Winterhold · The Great Town of Ivarstead ·
The Great Village of Kynesgrove · The Old Ways · Thuldor's Ivarstead · Winterhold Restored.

Every patch masters onto `WintersunNordicDivines.esp`, so the main addon installs first.

## Repository layout

```
src/                                       # SOURCE OF TRUTH - all committed
  WintersunNordicAddon/
    NordicAddonESP/                        # WintersunNordicDivines.esp as Spriggit YAML
    TribunalPatchESP/                      # WintersunNordicAddonTribunalPatch.esp as YAML
    NordicAddonScripts/source/             # Papyrus .psc
    NordicAddonScripts/compiled/           # .pex - committed on purpose (see "CI build" below)
  WintersunNordicAddonPatchesCollection/
    <Patch>/                               # one Spriggit YAML folder per patch plugin

build/
  manifest.json                            # which YAML folders build into which release archive
  build.ps1                                # the whole build (local + CI)
  Test-RecordYaml.ps1                      # structural lint for hand-edited record YAML
  releases/<Release>/fomod/                # COMMITTED FOMOD installer source
  staging/<Release>/                       # derived, gitignored - wiped every build
  dist/<Archive>.7z                        # derived, gitignored - the shippable archives

reference/                                 # gitignored: Wintersun + base-master decompiles, lookup only
arch-docs/                                 # record-pattern notes
.claude/                                   # skills, subagents, tool config (committed except tools.json)
```

## First-run setup on a new machine

A clone brings the source, the skills and the config **template** — but not machine-specific paths,
the binary plugins, or any third-party reference material (all gitignored).

1. **Create your tool config** from the committed template:

   ```powershell
   Copy-Item ".claude/config/tools.example.json" ".claude/config/tools.json"
   ```

2. **Install the Spriggit CLI.** Grab the `SpriggitCLI.zip` for **0.40.0** from the
   [Spriggit releases](https://github.com/Mutagen-Modding/Spriggit/releases), unzip it anywhere,
   install the .NET runtime if prompted, and set `spriggitCli` in `tools.json` to the
   `Spriggit.CLI.exe` path. Matching the version in `.spriggit` is what keeps everyone producing
   byte-identical plugins. See [Installing Spriggit](#installing-spriggit).

3. **Point at your game / MO2 instance.** Fill in `gameRoot`, `gameDataDir`, `modsDir` and
   `deployModName`. With a Wabbajack list, `gameRoot` is usually `<instance>/Stock Game` — a
   self-contained game copy, so the list never touches your Steam install.

4. **Only if you will compile Papyrus:** set `papyrusCompiler` (the Creation Kit's
   `PapyrusCompiler.exe`) and `gameSourceScripts` (the vanilla `.psc` + `TESV_Papyrus_Flags.flg`;
   extract `<gameDataDir>/Scripts.zip` once if that folder is empty). Add the Wintersun script
   source dir to `importDirs` — any script referencing a Wintersun type needs it.

5. **Verify** the tools you actually need resolve:

   ```powershell
   . ".claude/config/tools.ps1"
   Assert-Tool $Tools.spriggitCli     'spriggitCli'
   Assert-Tool $Tools.papyrusCompiler 'papyrusCompiler'   # only if you'll compile scripts
   $Tools | ConvertTo-Json -Depth 4
   ```

   `Assert-Tool` throws on a missing or empty path — fix those before running the skills.

You can build the archives with **only** step 1 + 2 done: `build/build.ps1` needs nothing but the
Spriggit CLI and 7-Zip.

## The round-trip workflow

```
.esp  ──serialize──►  YAML under src/ (committed)  ──deserialize──►  .esp
          ▲                                                            │
          └────────────────── you edit the YAML ◄──────────────────────┘
```

1. Edit the YAML as text (use the `spriggit-record-editor` subagent for new records).
2. `build/build.ps1` deserializes it back into plugins and packs the archives.
3. Load the rebuilt plugin in xEdit / the Creation Kit, then test in an MO2 profile.

Serializing is only needed when importing a plugin that was edited in the CK, or when decompiling
a reference master for lookups.

### Spriggit commands (CLI 0.40.0)

Paths come from `.claude/config/tools.json` via `. ".claude/config/tools.ps1"`.

```powershell
# Serialize (plugin -> YAML)
. ".claude/config/tools.ps1"
& (Assert-Tool $Tools.spriggitCli 'spriggitCli') serialize `
  --InputPath   "WintersunNordicDivines.esp" `
  --OutputPath  "./src/WintersunNordicAddon/NordicAddonESP" `
  --GameRelease $Tools.spriggit.gameRelease `
  --PackageName $Tools.spriggit.packageName `
  --PackageVersion $Tools.spriggit.packageVersion

# Deserialize (YAML -> plugin). --PackageName/--PackageVersion are auto-detected
# from the folder's spriggit-meta.json.
& (Assert-Tool $Tools.spriggitCli 'spriggitCli') deserialize `
  --InputPath   "./src/WintersunNordicAddon/NordicAddonESP" `
  --OutputPath  "WintersunNordicDivines.esp"
```

Reference masters (Wintersun, `Skyrim.esm`, DLC) are serialized into the **gitignored**
`reference/` tree — lookup only, never committed. Use the `spriggit-decompile-reference` skill.

## Building

The build is data-driven by [`build/manifest.json`](build/manifest.json) — it contains no
mod-specific logic. For each release it:

1. wipes `build/staging/<release>/` and copies in the committed
   `build/releases/<release>/fomod/` installer,
2. deserializes each listed YAML folder into the release's `.esp`,
3. copies the committed `.pex` into `Scripts/`,
4. packs the staging tree to `build/dist/<archiveName>.7z`,

then prints each archive's size and SHA-256.

```powershell
build/build.ps1              # full build -> build/dist/*.7z (+ a size/SHA-256 summary)
build/build.ps1 -CheckFomod  # only verify manifest <-> fomod/ModuleConfig.xml parity
build/Test-RecordYaml.ps1    # structural lint of the record YAML (BOM/CRLF/tabs/EditorID drift)
```

Windows PowerShell 5.1 and PowerShell 7 both run these. `-CheckFomod` needs neither Spriggit nor
7-Zip, so it is the fast pre-commit check after touching a `ModuleConfig.xml`.

### Source vs. derived

| Committed | Derived (gitignored) |
|---|---|
| `src/**` — plugin YAML + Papyrus `.psc` | `build/staging/`, `build/dist/`, `*.esp`, `*.7z` |
| `build/releases/<release>/fomod/` — installer XML (+ images) | everything staging copies or generates |
| `src/…/NordicAddonScripts/compiled/*.pex` (**deliberate exception**) | `reference/`, `dist/` |

**Adding a plugin?** Add it to `build/manifest.json` *and* to that release's `ModuleConfig.xml` —
`-CheckFomod` fails the build if a FOMOD installs an `.esp` the manifest never builds, and warns
when the manifest builds one the FOMOD never installs. The `mod-new-plugin` skill does both.

**FOMOD images:** `path=` is relative to the **archive root**, so it must carry the `fomod\` prefix
itself and use backslashes; progressive JPEGs render blank in MO2. `-CheckFomod` checks all three.

## Papyrus scripts

| Step | Tool | Config key |
|------|------|------------|
| Extract `.bsa`/`.ba2` | BSA Browser CLI (`bsab.exe`) | `$Tools.bsab` |
| Decompile `.pex` → `.psc` | Champollion | `$Tools.champollion` |
| Compile `.psc` → `.pex` | Papyrus Compiler (CK) | `$Tools.papyrusCompiler` |
| Open the editor | Creation Kit | `$Tools.creationKit` |
| Build `.esp` | Spriggit | `$Tools.spriggitCli` |

```
.bsa/.ba2 ──bsa-extract──► .pex ──pex-decompile──► .psc ──(edit)──► .psc
                                                                      │
   dist/<ModName>/ ◄──package-mod──┬── .pex ◄──papyrus-compile────────┘
   (mod-deploy into MO2)           └── <ModName>.esp ◄──spriggit-deserialize
```

Wintersun's own 193 decompiled scripts live under `reference/mods/wintersun/wintersunScripts/source/`
— **read the relevant one before authoring anything that touches favor, tenets or the tracker
quest's arrays.** `CLAUDE.md` lists which file answers which question.

## CI build & release (GitHub Actions)

[`.github/workflows/build.yml`](.github/workflows/build.yml) rebuilds both archives on every push to
`main` — as a **smoke test only, publishing nothing** — and cuts a named GitHub Release when you
push a `v*` tag. It also runs on `workflow_dispatch` for a manual rebuild. The shared setup+build
steps live in the composite action [`.github/actions/build-mod-archives/`](.github/actions/build-mod-archives/action.yml),
used by both workflows, so the build invocation exists in exactly one place.

The action reads the **Spriggit version from `.spriggit`** — the same file that pins the serializer
for the committed YAML — so CI cannot drift from what the YAML was written with. Nothing pins a
version in the workflow files.

To release: `git tag v2.0 && git push origin v2.0` → both `.7z` are built and attached to a Release
named `v2.0`. The `github-release` skill drives the curated flow: changelog from the previous tag,
tag push, watch the build, then replace CI's generated notes and mark the release Latest.

**Archives reach you in exactly two ways:** a **PR artifact** while a change is in review, and a
**`v*` tag Release** when it ships. Nothing is published from `main`.

**PR test builds.** [`.github/workflows/pr-build.yml`](.github/workflows/pr-build.yml) runs the same
build on every pull request and attaches both archives as an Actions artifact named
`pr-<number>-test-builds`, plus a sticky comment with their SHA-256 hashes. Each push replaces the
previous artifact; merging or closing the PR deletes it. (Fork PRs get a read-only token, so the
comment/delete steps only work for branches pushed to this repo.)

### CI does NOT compile Papyrus

The Creation Kit compiler and the licensed base-game script source cannot run on a cloud runner, so
the compiled scripts are **committed** at `src/WintersunNordicAddon/NordicAddonScripts/compiled/*.pex`
(an explicit exception in `.gitignore`).

> **Contract:** whenever you change a `.psc`, recompile (`/papyrus-compile`) and **commit the updated
> `.pex`**, or the packaged archive ships stale scripts. `build/build.ps1` fails on a *missing*
> `.pex` — it cannot detect a *stale* one.

## Installing Spriggit

Spriggit converts Bethesda plugins to and from a git-friendly text format. It ships as a **CLI**
(`Spriggit.CLI.exe`, what this workspace uses — needs a .NET runtime) and a **GUI** (Windows desktop
app, friendlier for one-off conversions). Download either from the
[Releases page](https://github.com/Mutagen-Modding/Spriggit/releases) and unzip; there is nothing to
register globally. Set the CLI path once in `.claude/config/tools.json` — if you move or upgrade it,
edit that one file, never a skill.

The serializer itself (`Spriggit.Yaml.Skyrim`) is a NuGet package the CLI fetches on demand; the
[`.spriggit`](.spriggit) file pins its name and version so `deserialize` always downloads the exact
serializer the YAML was created with.

## Claude skills & subagents

Committed under `.claude/`, so they are shared with anyone who clones the repo. They bundle the
verified CLI paths and flags.

**Skills** (invoke with `/<name>`):

| Skill | What it does |
|-------|--------------|
| `spriggit-serialize` | Serialize a plugin → its YAML folder |
| `spriggit-deserialize` | Rebuild a plugin from its YAML folder (+ xEdit/CK verify reminder) |
| `spriggit-decompile-reference` | Serialize a vanilla/third-party master into gitignored `reference/` for lookups |
| `formkey-check` | Scan the workspace for FormID collisions or the next free block |
| `mod-new-plugin` | Scaffold a new plugin: YAML header + manifest entry (+ FOMOD wiring) |
| `bsa-extract` | Extract/list files (e.g. `*.pex`) from a `.bsa`/`.ba2` |
| `pex-decompile` | Decompile `.pex` → editable `.psc` (Champollion) |
| `papyrus-compile` | Compile `.psc` → `.pex` (CK `PapyrusCompiler.exe`) |
| `package-mod` | Assemble `dist/<ModName>/` (esp + scripts) for MO2 testing |
| `mod-deploy` | Copy the packaged mod into an MO2 instance and verify it landed |
| `github-release` | Cut a versioned Release — changelog, tag push, then curate CI's notes |

**Subagents:**

| Subagent | Role |
|----------|------|
| `spriggit-record-editor` | Creates/edits Spriggit YAML records following the naming & FormKey conventions |
| `spriggit-formkey-auditor` | Read-only audit for collisions, dangling refs, broken cross-record invariants |
| `papyrus-script-engineer` | Cleans decompiled `.psc`, fixes compile errors, drives extract→compile→package |

A committed `PostToolUse` hook runs `build/Test-RecordYaml.ps1` on every YAML edit, so a BOM, a tab,
CRLF endings, an EditorID that disagrees with its filename, or an out-of-range ESL FormID is caught
as you type rather than at build time.

## Gotchas

- **Tenet enforcement is hardcoded by deity index** inside Wintersun's compiled tracker quest. A new
  deity's tenet MGEF is **cosmetic** unless you add the logic yourself — see *Critical compiled-script
  gotcha* in `CLAUDE.md`.
- **The per-deity parallel arrays must stay the same length.** Extend every one of them in a single
  pass, then run the length audit (`spriggit-formkey-auditor`).
- **`WintersunNordicDivines.esp` is ESL-flagged** — new FormIDs must stay inside `0x800–0xFFF`. Grep
  before assigning (`formkey-check`); `CLAUDE.md` tracks the next free block.
- **Decompiled `.psc` is a reconstruction**, not the author's original — auto-named variables,
  reconstructed control flow, lost comments. A clean compile proves it *builds*, not that it *runs*.
- **Missing-type compile errors** mean the referenced API's source is not on the import path — add
  its `Source\Scripts` dir to `importDirs` in `tools.json` and record it in `CLAUDE.md`.

## License

See [LICENSE](LICENSE). Wintersun – Faiths of Skyrim is the work of Enai Siaion and is not
redistributed here; this repository contains only its own records, patches and scripts.
