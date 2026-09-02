# Wintersun Nordic Addon (2.0) — Spriggit Workspace Guide

Extends **Wintersun – Faiths of Skyrim** (Enai Siaion) with new Nordic deities — tenets,
blessings, boons, devotee effects, and map markers — authored as **Spriggit YAML** and re-packed
to a plugin. The addon plugin is **`WintersunNordicDivines.esp`** (ESL / `Small`-flagged), which
masters onto Wintersun and overrides its central quest to append new deities.

## What this is

A Spriggit YAML workspace for **SkyrimSE**. Plugins are decompiled to YAML, edited as text,
and re-packed to `.esp`/`.esm`. **Never hand-edit binary plugins — edit the YAML.**

- Spriggit package/source: `Spriggit.Yaml.Skyrim`
- Spriggit CLI version: `0.40.0`
- CLI path + all tool paths: `.claude/config/tools.json` (gitignored; see Tooling config below).

## Knowledge base (oculory-rag) — search it before answering

If the `oculory-rag` MCP tools are available, use them **before** answering from memory and
before grepping `reference/` by hand:

- **`search`** — the written knowledge base: engine behaviour, record patterns, SPID, Spriggit
  and Mutagen workflow, third-party mod analyses, prior art and design notes.
- **`game_search` / `game_read`** — the decompiled game files themselves: ~331k records and
  ~19k Papyrus scripts, looked up by EditorID, FormID, FormKey or in-game name. Prefer these
  over walking `reference/` by hand; they are indexed and answer in milliseconds.
- Pass `game="skyrim"` for this repo, so Enderal facts do not leak into a Skyrim answer.

Cite the doc id or FormKey a claim rests on, and keep the `[verified]` / `[community]` /
`[unverified]` marks honest — retrieved text is evidence, not proof.

These tools are an optional local index. If they are not present, work in this repo exactly as
before: nothing here depends on them.

## Tooling config (no hardcoded paths)

All tool paths and per-machine settings live in **`.claude/config/tools.json`** (gitignored;
template at `tools.example.json`). Skills load it via `.claude/config/tools.ps1`, which exposes
`$Tools` (e.g. `$Tools.spriggitCli`, `$Tools.papyrusCompiler`, `$Tools.creationKit`,
`$Tools.gameSourceScripts`) and an `Assert-Tool` guard. **Never reintroduce a hardcoded path into a
skill — change the config instead.**

- **Setup:** copy `tools.example.json` → `tools.json` and fill in this machine's paths by hand.
  (There is no installer skill; a `modlist-install` skill used to exist and was removed.)
- **Modlists:** a Wabbajack list installs a full MO2 instance (its own game copy + mods + tools,
  often the **Creation Kit** and Papyrus compiler) and can be hundreds of GB — always gitignored
  (`/modlist/`, `/downloads/`). `gameRoot` is then usually `<instance>/Stock Game`.
- **This machine** points at the MO2 instance at `C:/modding/modlists/Baseline` (audited
  2026-08-30; the instance used to live at `C:/modding/Baseline` — **any note still saying that is
  stale**). Resolvable there: the Creation Kit, `PapyrusCompiler.exe`, `modsDir`, xEdit
  (`SSEEdit.exe`, `SSEEditQuickAutoClean.exe`, *Edit Scripts*), Synthesis, Cathedral Assets
  Optimizer, LOOT, NifSkope, BethINI — plus the Spriggit CLI at `C:/Tools/SpriggitCLI` and ReSaver
  in the sibling `LoreRim` instance. **Not present anywhere on this machine:** `bsab`, Champollion,
  BSArch, Octagon, BAE — **so `.bsa` extraction and `.pex` decompiling still cannot run here.**
- **The one thing blocking Papyrus compiling is the base-game source, not the compiler.**
  `Stock Game/Data` has no `Source/` folder and no `Scripts.zip` — MO2 serves scripts through the
  VFS, so the vanilla `.psc` set is not on disk, and neither is `TESV_Papyrus_Flags.flg` (the only
  copies ship with Nemesis). Two partial sets exist and are recorded in `tools.json`'s
  `_gameSourceScripts_status`: SKSE's `Scripts/Source` (62 SKSE-extended core types — `Actor`,
  `Game`, `Utility`, `Math`, `Weather`, `ActiveMagicEffect`, `Perk`, `Quest`; **no** `Debug`,
  `ReferenceAlias`, `Message`, `GlobalVariable`) and PapyrusUtil's. Drop a Steam SkyrimSE
  `Data/Scripts.zip` into `Stock Game/Data/Source/Scripts` and compiling works for the first time;
  add those two dirs to `importDirs` at the same time. Everything Spriggit- and build-related works.

## Workflow (round-trip)

- Serialize (plugin → YAML) and deserialize (YAML → plugin) commands: see `README.md`.
- After editing YAML, deserialize and load the plugin in xEdit/CK to verify before shipping.

## Folder map

**All authored source lives under `src/`** — that prefix is mandatory in every path, manifest entry
and skill invocation.

- `src/WintersunNordicAddon/NordicAddonESP/` — the addon plugin `WintersunNordicDivines.esp` as YAML
  (**committed** — source of truth).
- `src/WintersunNordicAddon/TribunalPatchESP/` — `WintersunNordicAddonTribunalPatch.esp` as YAML
  (optional CC-Tribunal deities; ships inside the main archive as a FOMOD option).
- `src/WintersunNordicAddon/NordicAddonScripts/source/` — the addon's Papyrus `.psc` (**committed**);
  `…/compiled/` holds the built `.pex` — **also committed**, by explicit `.gitignore` exception,
  because CI cannot run the Creation Kit compiler.
- `src/WintersunNordicAddonPatchesCollection/<Patch>/` — one Spriggit YAML folder per compatibility
  patch (18 of them; **committed**). They ship as the second release archive.
- `build/` — `manifest.json` (what builds into which archive), `build.ps1`, `Test-RecordYaml.ps1`,
  and `releases/<Release>/fomod/` (committed FOMOD source). `build/staging/` and `build/dist/` are
  derived and gitignored. See **Build & release** below.
- `reference/mods/wintersun/wintersunEsp/` — Wintersun's plugin as YAML, **lookup only** (gitignored).
- `reference/mods/wintersun/wintersunScripts/source/` — Wintersun's 193 decompiled `.psc`,
  **read these before authoring scripts** (gitignored).
- `reference/Base/{01Skyrim,02Update,03Dawnguard,04Hearthfire,05Dragonborn}/` — base masters as YAML
  for FormKey lookups (gitignored).

> The whole `reference/` tree and any MO2 instance are gitignored — third-party content,
> re-serialized locally per machine. Of the mod itself, `src/` + `build/releases/` are committed.

## Architecture / core records

Wintersun centers on one massive quest, **`WSN_TrackerQuest_Quest`**
(FormKey `005901:Wintersun - Faiths of Skyrim.esp`), whose Papyrus script
(`wsn_trackerquest_quest.psc`) holds **parallel arrays indexed per deity (0-based)**. Every new
deity is appended to the end of *every* relevant array. **The arrays MUST stay the same length —
if you extend one, audit them all.** The addon carries an override of this quest at
`src/WintersunNordicAddon/NordicAddonESP/Quests/WSN_TrackerQuest_Quest - 005901_Wintersun - Faiths of Skyrim.esp.yaml`.

### Deity index map (from the live `WSN_DeityName` array — length 60)

Vanilla Wintersun fills indices **0–51**. **This addon appends indices 52–59:**

| Index | Deity | EditorID prefix | Notes |
|------:|-------|-----------------|-------|
| 4 | Mara | — | vanilla Divine (DivineTypeID 0) — reference |
| 9 | Dibella | — | vanilla Divine — reference |
| 17 | Kynareth | — | vanilla Divine — reference |
| 52 | Kyne | `Kyne` | addon |
| 53 | Jhunal | `Jhunal` | addon |
| 54 | Stuhn | `Stuhn` | addon |
| 55 | Tsun | `Tsun` | addon |
| 56 | Orkey | `Orkey` | addon |
| 57 | Mara (Nordic) | `NAMara` | addon — Nordic Mara variant |
| 58 | Dibella (Nordic) | `NADibella` | addon — Nordic Dibella variant |
| 59 | Alduin | `Alduin` | addon |

When adding another deity it becomes index **60**, and every per-deity array below grows to length 61.

### Per-deity parallel arrays in `WSN_TrackerQuest_Quest` (must stay aligned)

Extend **each** of these by exactly one entry per new deity:

`WSN_Blessing` · `WSN_Boon1` · `WSN_Boon2` · `WSN_DeityName` (string) ·
`WSN_DivineType` (string) / `WSN_DivineTypeID` (int) · `WSN_DrainRateMultIndividual` (float, def 1) ·
`WSN_DynamicStat0/1/2` (stat name) + `_Multiplier` (global) · `WSN_FavorDisplay` (string) ·
`WSN_FavoredRace0/1` · `WSN_PrayerRateMultIndividual` (float, def 1) · `WSN_PreviousFavor` (float, def 0) ·
`WSN_Quest_Multiplier` / `WSN_QuestIsCompleted` / `WSN_QuestToComplete` ·
`WSN_StatBuffToGains` (string) + `_Multiplier` · `WSN_StaticAttr` / `WSN_StaticSkills` /
`WSN_StaticStat0/1/2` (string) + `_Multiplier` · `WSN_Tenet` (tenets ability spell).

**NOT per-deity** — do **not** extend these bucket arrays: `WSN_DrainRateMult` (7 entries) and similar.

**Validation rule:** before finishing any deity addition, assert every per-deity array has identical
length. Use the `spriggit-formkey-auditor` subagent / `formkey-check` skill.

### Critical compiled-script gotcha (tenets are cosmetic)

Tenet enforcement (marriage, follower-count, bounty, house ownership) for vanilla deities is
**hardcoded inside the compiled `wsn_trackerquest_quest.pex` by deity index**. A new deity at index
52+ inherits **none** of it. The tenet MGEF (Script archetype, no attached script) is **cosmetic
only** unless you either:

1. Decompile `wsn_trackerquest_quest.pex`, add `if deityID == N` blocks mirroring a vanilla deity's
   logic, recompile — **or**
2. Add a standalone ReferenceAlias-on-player script that polls a stat and writes to
   `(WSN_TrackerQuest as WSN_TrackerQuest_Quest).WSN_PreviousFavor[N]` directly.

`WSN_DynamicStat0/1/2` + their `_Multiplier` arrays **do** grant favor from stat changes via the
existing compiled logic — those work for new indices without script edits.

## FormKey discipline

- New records use this plugin's name as the FormKey suffix: `<hex>:WintersunNordicDivines.esp`.
  Records that **override** a Wintersun/base record keep the original suffix (e.g. the TrackerQuest
  override is `005901:Wintersun - Faiths of Skyrim.esp`).
- **`WintersunNordicDivines.esp` is ESL (`Small`) — FormIDs are constrained to `0x800–0xFFF`.**
  Confirm with the user before exceeding; there is headroom but it is finite.
- Allocate a **contiguous ~12-key block per new deity** for readable diffs.
- **Current usage (audited, 153 records):** `0x800–0x88F` (deities 52–59) · `0x890–0x892` (Nordic
  TypeID 7 globals) · `0x893–0x896` (Horn of First Tongues item + distribution quest) ·
  `0x8A0–0x8B8` (later per-mechanic work: Jhunal prayer node + skill menus, Orkey/Tsun powers,
  Tsun trial-by-combat faction/perks/globals, Alduin shout perk, Kyne & Mara favor globals).
  **Next free: `0x8B9` and up.** `0x897–0x89F` is still free too (old reserved headroom), as are
  scattered holes: `0x80C–0x80D`, `0x82C–0x82D`, `0x83D–0x848`, `0x861`, `0x872`, `0x87A–0x87D`,
  `0x883`, `0x88E`. Prefer a fresh block above `0x8B9`; the holes are for one-offs.
- ALWAYS grep the whole workspace (`src/` + `reference/`) for a hex FormID before assigning it —
  use the `formkey-check` skill. Re-audit rather than trusting the numbers above if they look stale:
  `grep -rhoE '^FormKey: [0-9A-F]{6}:WintersunNordicDivines\.esp' src/WintersunNordicAddon/NordicAddonESP`.

## Record patterns / templates

### Record set per new deity (standard pattern)

Allocate a contiguous FormKey block (~12 keys). Use an existing addon deity (**Tsun, Stuhn, Orkey**)
as the canonical template to copy — read its full record set first. Create, per deity:

| Record | Type | Notes |
|--------|------|-------|
| `WSN_AltarBlessing_<Deity>_Effect` | MagicEffect | `PeakValueModArchetype`; ActorValue matches blessing theme; `Association: 0FB98C:Skyrim.esm` (Blessing keyword); `PowerAffectsMagnitude` flag; `PerkToApply` → Boon1 perk |
| `WSN_AltarBlessing_<Deity>_Spell` | Spell | Blessing type; three effects: blessing MGEF, vanilla `0FBFF5` (`CureDiseaseEffect` — the cure-disease effect every vanilla shrine blessing carries), worship-request MGEF (conditional) |
| `WSN_Shrine_Effect_WorshipRequest_<Deity>` | MagicEffect | Script archetype; `WSN_DeityID = <index>`; links worship-request message |
| `WSN_WorshipRequest_Message_<Deity>` | Message | MessageBox, Accept/Cancel |
| `WSN_Basic_Message_<Deity>` | Message | `Favor with <Deity>: %.1f%%` template |
| `WSN_Divine_<Deity>_Tenets_Effect_Ab` | MagicEffect | Script archetype — **cosmetic description only** (see gotcha above) |
| `WSN_Divine_<Deity>_Tenets_Spell_Ab` | Spell | Ability holding the tenets MGEF |
| `WSN_Divine_<Deity>_Boon1_Effect_Ab` | MagicEffect | `PeakValueModArchetype`; `PerkToApply` → Boon1 perk |
| `WSN_Divine_<Deity>_Boon1_Spell_Ab` | Spell | Ability with magnitude (Wintersun convention: 15) |
| `WSN_Divine_<Deity>_Boon1_Perk` | Perk | `PerkEntryPointModifyValue`. Use **flat `Multiply: <ratio>`** for inventory-card visibility; `MultiplyOnePlusAVMult` does **not** update inventory display |
| `WSN_Divine_<Deity>_Boon2_Effect_Ab` | MagicEffect | `MagicEffectCloakArchetype`; links to FAF Aimed proc spell |
| `WSN_Divine_<Deity>_Boon2_Spell_Ab` | Spell | Devotee ability; cloak-radius magnitude (40) |
| `WSN_Divine_<Deity>_Boon2_Spell_CloakProc` | Spell | FAF Aimed proc spell |
| `WSN_Divine_<Deity>_Boon2_Effect_ProcOnTarget_<Theme>` | MagicEffect | Real effect; conditions: cooldown marker absent + random gate + target filters |
| `WSN_Divine_<Deity>_Boon2_CooldownMarker` | MagicEffect | Script archetype; used purely as a "do I have this?" flag |
| `Shrineof<Deity>` | Activator | `defaultTempleBlessingScript`; links blessing spell + message |
| `Altar<Deity>Msg` | Message | "Blessing of `<Deity>` added" |

**Build order (bottom-up):** perks → MGEFs → spells → activator → message. **Wire the TrackerQuest
arrays last**, in one pass, adding the new index to every per-deity array; then run the length audit.

**Naming when a deity deviates from the template.** The Boon2 rows above describe the *cloak* pattern
(`…_Boon2_Spell_Ab` + `…_Spell_CloakProc` + `…_Effect_ProcOnTarget_<Theme>`). Several deities do not
use a cloak — Stuhn's Ransom, Orkey's and Tsun's boons are **lesser powers** — and there the records
are named after the mechanic instead (`WSN_Divine_Stuhn_Boon2_Power`, `…_Power_Effect`,
`…_FleeSpell`, `…_FleeEffect`). That is correct and intended; do not "fix" such names back to the
cloak template.

**The filename must equal the `EditorID:` inside it.** Spriggit writes
`<EditorID> - <FormID>_<Plugin>.esp.yaml` on every serialize, so a hand-authored file whose name
disagrees will silently rename itself on the next round-trip — and, because Spriggit orders records
within a group by filename, the rebuilt `.esp` reorders too. The `Test-RecordYaml.ps1` hook flags the
mismatch on save; fix it by **renaming the file**, not by editing the EditorID.

### Map markers

Map markers live in the **Tamriel worldspace persistent cell**
(`reference/mods/wintersun/wintersunEsp/Worldspaces/Tamriel - 00003C_Skyrim.esm/…` for reference; the
addon's own markers go in its Worldspaces override, under `Persistent:`). **Two `PlacedObject`
records per marker:**

```yaml
- MutagenObjectType: PlacedObject
  FormKey: <markerKey>:WintersunNordicDivines.esp
  MajorRecordFlagsRaw: 1024
  EditorID: WSN_ShrineOf<Deity>_MapMarker
  SkyrimMajorRecordFlags: [0x400]
  Base: 000010:Skyrim.esm                 # MapMarker base
  LocationRefTypes: [10F63C:Skyrim.esm]   # MapMarkerRef — REQUIRED or it won't be discoverable
  LinkedReferences:
  - Reference: <linkKey>:WintersunNordicDivines.esp
  MapMarker:
    Name: { TargetLanguage: English, Value: Shrine of <Deity> }
    Type: Shrine
  Placement:
    Position: <X>, <Y>, <Z>
- MutagenObjectType: PlacedObject
  FormKey: <linkKey>:WintersunNordicDivines.esp
  MajorRecordFlagsRaw: 1024
  SkyrimMajorRecordFlags: [0x400]
  Base: 000034:Skyrim.esm                 # XMarkerHeading (NOT plain XMarker, which is 00003B)
  Placement:
    Position: <X+300>, <Y>, <Z>
    Rotation: 0, 0, 0
```

Get shrine coordinates from the **PlacedObject of the shrine activator inside its POI cell**
(`…/Worldspaces/Tamriel - 00003C_Skyrim.esm/<block>/<sub>/POI*`) — the `Position` field there is
canonical. Do **not** read coordinates from the console.

## Useful FormKey constants

| FormKey | Meaning |
|---------|---------|
| `000010:Skyrim.esm` | MapMarker base |
| `000034:Skyrim.esm` | `XMarkerHeading` — the marker a map marker links to. Plain `XMarker` is `00003B`; do not swap them |
| `000014:Skyrim.esm` | PlayerRef |
| `000038:Skyrim.esm` | GameHour global |
| `000039:Skyrim.esm` | GameDaysPassed global |
| `00003C:Skyrim.esm` | Tamriel worldspace (map markers live in its persistent cell) |
| `0BCC98:Skyrim.esm` | PlayerFollowerCount global |
| `0C6472:Skyrim.esm` | PlayerMarriedFaction |
| `0FB98C:Skyrim.esm` | Blessing keyword (PeakValueMod association) |
| `0FBFF5:Skyrim.esm` | `CureDiseaseEffect` ("Cure Disease") — the second effect on every vanilla/Wintersun shrine blessing. Not a favor effect, despite older notes here calling it "Favor of the Gods" |
| `10F63C:Skyrim.esm` | MapMarkerRef LocationRefType |
| `005901:Wintersun - Faiths of Skyrim.esp` | `WSN_TrackerQuest_Quest` (the central quest) |
| `00F93C:Wintersun - Faiths of Skyrim.esp` | Tenets MenuDisplayObject |

## Plugin header

**All 20 plugin headers are set and must stay consistent** — every `RecordData.yaml` carries:

```yaml
ModHeader:
  Flags:
  - Small            # ESL; not on plugins that should stay full-size
  Author: WhisperDealer
  Stats:
    Version: 1.71    # SSE header version. Wrye Bash rejects 0.85-style (LE) versions.
```

Give any new plugin the same two fields. Notes:

- `Version` is pinned explicitly even though Mutagen already defaults to `1.71`, so a future Spriggit
  default cannot silently change what ships.
- **`Stats.NumRecords` / `NextFormID` are recalculated by Mutagen on every write** — do not hand-write
  them. (After a build the addon reports 229 records and NextFormID `0x8B9`, which is exactly the next
  free FormID from the audit above.)
- Header `Description` (SNAM) is deliberately unset; mod-manager blurbs live in each release's
  `build/releases/<Release>/fomod/info.xml` instead.

## Papyrus toolchain

Scripts go through extract → decompile → edit → compile → package. Use the matching skills; the
`papyrus-script-engineer` subagent handles decompiled-source cleanup and compile-error fixing.

**Tool paths:** all resolved from `.claude/config/tools.json` — do not hardcode. Keys per step:

| Step | Tool | Config key |
|------|------|------------|
| Extract `.bsa`/`.ba2` | `bsab.exe` | `$Tools.bsab` — **blank, not installed here** |
| Decompile `.pex`→`.psc` | `Champollion.exe` | `$Tools.champollion` — **blank, not installed here** |
| Compile `.psc`→`.pex` | `PapyrusCompiler.exe` | `$Tools.papyrusCompiler` — installed; blocked only by the missing base-game source |
| Open Creation Kit | `CreationKit.exe` | `$Tools.creationKit` — installed |

**Folder layout (this project):** `src/WintersunNordicAddon/NordicAddonScripts/source/` (committed
`.psc`, source of truth) · `src/WintersunNordicAddon/NordicAddonScripts/compiled/` (**committed**
`.pex` — `.gitignore` exception, CI packages these as-is) · `dist/<ModName>/` (gitignored packaged
mod) · `reference/mods/wintersun/wintersunScripts/source/` (Wintersun's 193 decompiled `.psc`,
gitignored).

> **Contract:** change a `.psc` → recompile (`/papyrus-compile`) → **commit the new `.pex`**. The
> build fails on a *missing* `.pex` but cannot detect a *stale* one, so a forgotten recompile ships
> silently broken scripts. Note that compiling **still cannot run on this machine** — the compiler
> itself is installed now, but the base-game `.psc` source and flags file are missing; see the
> tooling status above for exactly what to drop in.

### Wintersun reference scripts — read BEFORE authoring or wiring anything

All of Wintersun's decompiled source is at **`reference/mods/wintersun/wintersunScripts/source/`**.
When a task touches array indices, favor flow, tenet enforcement, or how `AddSpell`/`RemoveSpell` is
called, **read the relevant `.psc` there first** rather than inferring from YAML:

| File | When to read it |
|------|-----------------|
| `wsn_trackerquest_quest.psc` | Per-deity array layout & lengths, favor income logic, tenet enforcement, how Boon1/Boon2 are added/removed — **source of truth for current array counts** |
| `wsn_worshiprequest_script.psc` | Shrine worship-request flow (DeityID dispatch, favor thresholds) |
| `wsn_favormod_script.psc` / `wsn_favormodglobal_script.psc` | How favor deltas are applied — reuse these patterns for custom scripts |
| `wsn_makeweather_script.psc` | Forcing/releasing weather overrides (see the addon's Alduin storm power) |
| `wsn_killcloak_script.psc` / `wsn_hircinedeathcloak_script.psc` | Cloak + on-kill pattern templates (Boon2) |
| `wsn_turnthehourglass_script.psc` | Devotee ability that grants/removes a power (AddSpell/RemoveSpell pattern) |
| `wsn_collectorquest_script.psc` | DynamicStat / collector-quest favor pattern |
| `prkf_wsn_boon_misc_magnus_bo_04028ee4.psc` | Perk entry-point script template |

To grant favor from a tracked stat from your own script, write to
`(WSN_TrackerQuest as WSN_TrackerQuest_Quest).WSN_PreviousFavor[<index>]`.

**Compiler imports:** base-game source = `$Tools.gameSourceScripts`
(extract `<gameDataDir>/Scripts.zip` once, or use what the modlist ships — **neither exists here
yet**). Flags file: `$Tools.papyrusFlags`.

**Per-project import dirs** — persist in `tools.json`'s `importDirs` array (the `papyrus-compile`
skill appends them to `-i`). Mirror here as discovered:

| API / framework | Source `.psc` dir |
|-----------------|-------------------|
| **Wintersun types** (`WSN_TrackerQuest_Quest`, etc.) | `reference/mods/wintersun/wintersunScripts/source` — needed by any script that references a Wintersun type, e.g. `WSN_Divine_HornOfFirstTongues_Script`. **Not yet in `importDirs`:** the reference tree currently holds only `wintersunEsp`; the scripts have not been decompiled here, and a non-existent `-i` dir fails the compile. Add it once it exists. |
| _(base only)_ | The addon's `WSN_Divine_Alduin_StormPower_Script` compiles against **base-game source only** (`ActiveMagicEffect`, `Game`, `Math`, `Utility`, `Weather`). Add SKSE/SkyUI/MCM/PapyrusUtil dirs here only when a new script needs them. |

**Testing:** the MO2 instance at `$Tools.modlistRoot` (`C:/modding/modlists/Baseline`; the sibling
`C:/modding/modlists/LoreRim` is the other instance). Use the **`mod-deploy`** skill — it copies
`dist/<ModName>/` into `$Tools.modsDir` under the exact `$Tools.deployModName`
(`Wintersun - Nordic Addon`, **with the dash** — it must match the existing enabled MO2 folder) and
verifies it landed. A name mismatch is the #1 cause of "my change never showed up in-game": MO2
simply does not see the folder and the game runs fine without it — `deployModName` really was wrong
this way until 2026-08-30. The patch collection is a separate MO2 mod,
`Wintersun - Nordic Addon (Shrines Patch Collection)`. Then enable the mod + its `.esp`, set load
order, and launch through MO2.

## Build & release

Two archives come out of one data-driven build (`build/manifest.json` holds all mod-specific facts;
`build/build.ps1` holds none):

| Archive | Contents |
|---|---|
| `Wintersun - Nordic Addon.7z` | `WintersunNordicDivines.esp` + 18 `.pex`, + the Tribunal patch as a FOMOD option |
| `Wintersun - Nordic Addon (Patch Collection).7z` | the 18 compatibility patches, one FOMOD checkbox each |

```powershell
build/build.ps1 -CheckFomod   # manifest <-> ModuleConfig.xml parity (no Spriggit/7-Zip needed)
build/build.ps1               # full build -> build/dist/*.7z (+ a size/SHA-256 summary)
build/Test-RecordYaml.ps1     # structural YAML lint (also runs as a PostToolUse hook on save)
```

Runs under Windows PowerShell 5.1 (there is **no `pwsh` on this machine** — do not prefix these with
`pwsh`). Rules that bite:

- **FOMOD source lives in `build/releases/<Release>/fomod/`** and is committed.
  `build/staging/` is wiped and regenerated every run — never put source there.
- **Adding a plugin means two edits**: `build/manifest.json` *and* that release's `ModuleConfig.xml`.
  `-CheckFomod` fails when the FOMOD installs an `.esp` the manifest never builds, and warns when the
  manifest builds one the FOMOD never installs. The `mod-new-plugin` skill does both.
- **`dest` in the manifest must match `source=` in the FOMOD exactly**, spaces and all (several
  plugins have spaces in their names, e.g. `Nordic Wintersun - Berserkyr.esp`).
- **CI does not compile Papyrus** and does not pin a Spriggit version: `.github/actions/build-mod-archives`
  reads it from `.spriggit`, the same file that pins the serializer for the committed YAML. Bumping
  Spriggit means bumping `.spriggit` + every `spriggit-meta.json`, and re-serializing.
- Push to `main` → build only, nothing published; push a `v*` tag → named Release with both archives.
  Test builds for review are the PR artifacts. The `github-release` skill drives the tag-and-curate
  flow.

## Gotchas

- **Decompiled `.psc` is a reconstruction** (Champollion): auto-named vars, reconstructed control
  flow, lost comments/flags. Always recompile and test in-game; a clean compile is not proof.
- **Missing-type compile errors** → the referenced API's source isn't on the import path; add its
  `Source\Scripts` dir to `importDirs` in `tools.json` and record it in the imports table above.
- Edit `.psc`/YAML, never the binary `.pex`/`.esp`. Commit source, not build artifacts.

### Wintersun-specific pitfalls

- **Tenets are cosmetic without script work.** When the user asks to change tenet text/behavior, tell
  them what mechanic (if any) actually runs — enforcement is hardcoded by index in the compiled
  TrackerQuest `.pex`. See *Critical compiled-script gotcha* above.
- **`MultiplyOnePlusAVMult` on a Boon1 perk → the inventory card won't update.** Use flat
  `Multiply: <ratio>` instead.
- **Skipping one per-deity array = silent failure** — the deity ends up with no name, wrong type, or
  no favor income. Extend *every* per-deity array in one pass, then run the length audit.
- **Map markers without `LocationRefTypes: [10F63C:Skyrim.esm]`** won't behave as discoverable
  locations.
- **A cloak Boon2 with no cooldown marker** spams its effect every cloak tick — always gate on the
  `WSN_Divine_<Deity>_Boon2_CooldownMarker` MGEF.
- **Do not extend the bucket arrays** (`WSN_DrainRateMult`, 7 entries, etc.) — they are not per-deity.
- A clean compile proves it *builds*, not that it *runs* — test in an MO2 modlist before shipping.
- **A YAML filename that disagrees with its `EditorID:`** silently renames itself on the next
  serialize and reorders records in the rebuilt `.esp`. Rename the file to match the record.
- **Paths without the `src/` prefix are stale** — everything authored moved under `src/` (older
  notes, commit messages and the arch-docs prompt still show the pre-`src/` layout).
