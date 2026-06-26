# AGENTS.md — IceDOS **config** (this machine's live config)

> Utilizes the **IceDOS** framework. The full bible — module structure, config flow,
> the `icedos rebuild --build` test loop, `validate.*` helpers, dep loading — lives in
> **core**: <https://github.com/IceDOS/core/blob/main/AGENTS.md>
> (locally: `../core/AGENTS.md`). This file covers this **config repo** specifically.

## Non-negotiable rules
- Build/test only via the `icedos` CLI — **never `sudo nixos-rebuild`**.
- **Never** `git commit/stash/reset/pull/push` in any IceDOS repo — the user manages git
  between turns. Make edits and stop.
- `config.toml` defaults must mirror the owning module's `icedos.nix` defaults.
- Format with `icedos nixf .` after editing any `.nix`.

## Purpose
The **live, private** IceDOS configuration for this machine. Everything about the system
is described here; `core` turns it into a NixOS system. This is where you run the test
loop and where the local-checkout override toggles live.

## Layout
- `config.toml` — the system description (enabled repos/modules + every `icedos.*`
  option). The main file you edit.
- `.private.toml` — secrets/personal values, strict-merged with `config.toml` (a key in
  both = error).
- `flake.nix` — calls `icedos.lib.mkIceDOS { configRoot = self; }`. Has a commentable
  `path:` pin for testing a **local core** checkout.
- `extra-modules/` — advanced custom Nix/IceDOS modules for this machine. Eval errors
  from one name their source: `config#<name>` for an `icedos.nix` extra-module, or the
  on-disk path for a plain `default.nix`.
- `.state/` — generated flake/lock + `.cache/`. **Do not hand-edit.**

## Raw NixOS options from TOML

Any top-level table that **isn't** `icedos` (in `config.toml` or `.private.toml`) is
applied as raw NixOS config — nixpkgs types/validates it, there is **no** IceDOS schema.
Use it for plain options no IceDOS module exposes:

```toml
[programs.joycond-cemuhook]
enable = true

[services.joycond]
enable = true
```

- Reaches home-manager the usual way: `[home-manager.users.ice.programs.git]`.
- Works for anything TOML can express: bools, ints, strings (incl. enum/path options),
  scalar lists (e.g. `[boot] kernelParams = ["quiet"]`).
- **Can't** express packages (`pkgs.foo`), `null`, `mkForce`/`mkDefault`, or `lib.*` —
  use `extra-modules/<name>/default.nix` for those.
- Normal priority: setting an option an IceDOS module already sets = a clear nixpkgs
  conflict error (don't set the same thing twice).
- A stray top-level table (e.g. forgetting the `icedos.` prefix) fails loud as an
  unknown NixOS option — the intended safety net.

## Testing local repo edits (this machine's paths)

The maintainer keeps sibling checkouts under `/home/ice/Projects/icedos/`. To test a
local edit to a sibling repo, point its `overrideUrl` at the checkout in `config.toml`:

```toml
[[icedos.repositories]]
url = "github:icedos/apps"
overrideUrl = "path:/home/ice/Projects/icedos/apps"   # active = test local apps
```

- Current state: **apps** override is active; `kde`/`desktop`/`hardware`/`tweaks` have
  their `overrideUrl` lines commented (using upstream). Uncomment the one you need.
- For **core**: uncomment `inputs.icedos.url = "path:/home/ice/Projects/icedos/core";`
  in `flake.nix`, and use `icedos rebuild --update-core --build` (core needs
  `--update-core` even with the path pin).
- You may freely toggle these overrides on/off to test before/after — **revert them
  when done** so the committed config stays on upstream.
- Validate with `icedos rebuild --build` (no activation). Only `switch` (plain
  `icedos rebuild`) on explicit user request — it mutates the live system.

## Gotchas
- `path:` overrides auto-refresh every build; **core is the exception** (`--update-core`).
- `icedos rebuild --export-full-config` → `.state/.cache/full-config.json` to inspect the
  merged, evaluated config without building.
- sunshine / user systemd services aren't restarted by a rebuild — restart them manually
  (`systemctl --user restart …`) to pick up new generated configs.
