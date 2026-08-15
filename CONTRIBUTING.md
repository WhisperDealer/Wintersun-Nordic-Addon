# Contributing

Thanks for looking. This is the source repo for the **Wintersun Nordic Addon** — the plugins live
here as [Spriggit](https://github.com/Mutagen-Modding/Spriggit) YAML and are re-packed to `.esp` by
the build. **Edit the YAML, never a binary plugin**; a `.esp` in a diff is a bug, not a contribution.

Start with [`README.md`](README.md) for setup and the build, and [`CLAUDE.md`](CLAUDE.md) for how
Wintersun is wired (deity indices, the tracker quest's parallel arrays, the record templates, and the
traps that build cleanly and do nothing in-game). Reading the latter first will save you a rebuild.

## What's most useful

- **Compatibility patches.** A patch that puts the addon's shrines into another mod's town, temple or
  interior is the easiest high-value contribution — see [Adding a patch](#adding-a-patch).
- **Bug fixes** in records or Papyrus: a boon that doesn't fire, a marker that isn't discoverable, a
  tenet whose description promises a mechanic that no longer exists.
- **Text and balance passes** on tenets, boon descriptions and messages, especially where the wording
  claims behaviour the compiled logic doesn't actually implement.
- **Tooling** — `build/build.ps1`, `build/Test-RecordYaml.ps1`, the GitHub Actions workflows, the
  skills and subagents under `.claude/`.
- **Documentation** wherever the README or `CLAUDE.md` is wrong, stale, or assumes knowledge a
  newcomer won't have. Stale FormID or array-length numbers in `CLAUDE.md` are worth a PR on their own.

## What's out of scope

- **Bethesda assets or third-party mod content.** Nothing under `reference/`, `modlist/` or any MO2
  instance is committed, and it must stay that way. Before opening a PR run `git status` — if a
  `.esp`, `.bsa`, a `.pex` you didn't author, or a decompiled vanilla record has crept in, remove it.
  Patches carry only *your* records; the mod they patch stays a master, never a bundled copy.
- **`.claude/config/tools.json`.** Gitignored: it holds your machine's paths. If you need a new key,
  add it to `tools.example.json` (documented) and leave your real values out.
- **New deities**, unless you've discussed it first. Each one consumes a FormID block and an index in
  *every* per-deity array, and the tenet enforcement for it has to be written by hand — see the
  *Critical compiled-script gotcha* in `CLAUDE.md`.

## Adding a patch

Use the **`/mod-new-plugin`** skill — it scaffolds the YAML folder, the `build/manifest.json` entry
and the FOMOD wiring together, which is exactly where hand-rolling goes wrong. If you do it by hand:

1. Create `src/WintersunNordicAddonPatchesCollection/<Name>/` with a `RecordData.yaml` and a
   `spriggit-meta.json` matching [`.spriggit`](.spriggit). The header needs
   `Author: WhisperDealer`, `Stats: { Version: 1.71 }`, the `Small` flag if it should be ESL, and
   `WintersunNordicDivines.esp` among its masters.
2. Add it to `build/manifest.json` **and** to the patches release's
   `build/releases/Wintersun - Nordic Addon (Patch Collection)/fomod/ModuleConfig.xml`. The manifest `dest` and
   the FOMOD `source=` must match **exactly**, spaces included.
3. Say in the FOMOD `<description>` which mod (and which of its plugins) the patch requires. Users
   pick from that text alone.
4. New records use `<hex>:WintersunNordicDivines.esp`-style FormKeys only when they *override* an
   addon record; the patch's own new records use its own plugin name. ESL plugins are limited to
   `0x800–0xFFF` — run `/formkey-check` before assigning.

## Before you open a PR

1. **The build must pass**, from a clean checkout:

   ```powershell
   build/build.ps1 -CheckFomod     # manifest <-> ModuleConfig.xml parity; no Spriggit needed
   build/build.ps1                 # full build -> build/dist/*.7z
   ```

2. **The record check must pass** if you touched any plugin YAML:

   ```powershell
   build/Test-RecordYaml.ps1
   ```

   It also runs as a `PostToolUse` hook, so agent edits get checked as they happen. A filename that
   disagrees with the `EditorID:` inside it is an error — fix it by **renaming the file**, since
   Spriggit derives the name from the record and orders records within a group by filename.

3. **Round-trip stability** if you hand-edited a record: deserialize, re-serialize, and confirm the
   YAML comes back identical. Spriggit output is canonical; hand-authored YAML should match it
   byte-for-byte so nobody gets a spurious whole-file diff later.

4. **If you changed a `.psc`, recompile and commit the `.pex`.** CI cannot run the Creation Kit
   compiler, so the archives ship the committed bytecode. The build fails on a *missing* `.pex` but
   cannot detect a *stale* one — that one is on you.

5. **If you touched the tracker quest's per-deity arrays, audit every one of them.** They must all
   stay the same length; use the `spriggit-formkey-auditor` subagent or `/formkey-check`.

6. **Say how you tested it.** A clean build proves the plugin *builds*. State which modlist/profile
   you loaded it in and what you actually saw happen — for a patch, that the shrine exists, activates,
   and grants favor for the right deity.

Opening a PR triggers a test build that attaches both archives as an Actions artifact, with a sticky
comment linking to them and listing their SHA-256. Fork PRs get a read-only token, so that comment
step is skipped — the build itself still runs.

## Style

- **PowerShell targets 5.1.** `Set-StrictMode` is on; there is no `&&`, no ternary, no
  null-coalescing. Don't assume `pwsh` exists — invoke scripts as `build/build.ps1`, not
  `pwsh build/build.ps1`.
- **Never hardcode a tool path.** Resolve everything through `$Tools` from `tools.json`
  (`. ".claude/config/tools.ps1"`), and guard with `Assert-Tool`.
- **Keep the build data-driven.** Mod-specific names belong in `build/manifest.json` and the FOMOD
  XML; `build.ps1` should stay free of them.
- Match the surrounding prose. The docs explain *why*, not just *what* — a rule without its reason
  gets dropped the first time it's inconvenient.
