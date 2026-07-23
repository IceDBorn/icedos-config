#!/usr/bin/env python3
"""Migrate IceDOS config files from camelCase to kebab-case option paths.

Scans config.toml + extraConfigs dirs (matching lib/config-files.nix behaviour)
and renames all compound option-path keys that changed in the casing sweep:
    chore: snake case for option paths and camel case for bottom lvl keys

Leaf-level keys (memory, cores, enable, ...) keep their camelCase — only
multi-word path segments are converted.

Usage:
    python3 migrate-casing.py [--config-root DIR] [--apply]
"""

import argparse
import re
import sys
from pathlib import Path

# ---------------------------------------------------------------------------
# All camelCase → kebab-case renames from the casing sweep across 8 repos.
# Only compound option-path segments; leaf keys unchanged.
# ---------------------------------------------------------------------------
RENAMES: dict[str, str] = {
    # core
    "buildVm": "build-vm",
    # apps
    "desktopEntry": "desktop-entry",
    "headlessSession": "headless-session",
    "desktopCapture": "desktop-capture",
    # NOTE: autoStart → auto-start was only applied under steam.os-session,
    # not under sunshine (which still declares autoStart in camelCase).
    # Cannot be safely renamed globally — handle manually if needed.
    # hardware
    "wakeOnLan": "wake-on-lan",
    "echoCancellation": "echo-cancellation",
    "noiseCancellation": "noise-cancellation",
    "powerLimit": "power-limit",
    # kde
    "screenEdges": "screen-edges",
    "systemTray": "system-tray",
    "windowBehavior": "window-behavior",
    "splashScreen": "splash-screen",
    # cosmic
    "cosmicFiles": "cosmic-files",
    "brightnessControl": "brightness-control",
    "windowManagement": "window-management",
    "snapWindowsToEdges": "snap-windows-to-edges",
    # gnome
    "pinnedApps": "pinned-apps",
    # claude-icedos
    "statusLine": "status-line",
    # desktop
    "disableMonitors": "disable-monitors",
    "xdgDesktopPortal": "xdg-desktop-portal",
}

# After adding a new entry to RENAMES, re-run with --apply to pick up any
# files that were missed in previous runs.

# Pre-compile regexes: word-boundary match on the camelCase key.
# \b works correctly here because camelCase words don't contain hyphens,
# so they won't bleed into adjacent kebab-case segments.
_PATTERNS: list[tuple[re.Pattern, str]] = [
    (re.compile(rf"\b{re.escape(old)}\b"), new) for old, new in RENAMES.items()
]


# ---------------------------------------------------------------------------
# Config discovery — mirrors lib/config-files.nix logic
# ---------------------------------------------------------------------------

def find_config_root(start: Path | None = None) -> Path:
    """Walk up from *start* (default: cwd) looking for the IceDOS config root.

    Priority: config.toml (the IceDOS base) > flake.nix containing mkIceDOS.
    Stops at the first match — does NOT stop at any random flake.nix (e.g.
    config-migration's own flake).
    """
    here = (start or Path.cwd()).resolve()
    for d in [here, *here.parents]:
        if (d / "config.toml").is_file():
            return d
    # Second pass: look for an IceDOS flake (contains mkIceDOS)
    for d in [here, *here.parents]:
        flake = d / "flake.nix"
        if flake.is_file() and "mkIceDOS" in flake.read_text(errors="replace"):
            return d
    print("error: could not locate config root (no config.toml or IceDOS flake.nix found)", file=sys.stderr)
    sys.exit(1)


def extract_extra_configs(config_toml: Path) -> list[str]:
    """Regex-extract extraConfigs = [...] from config.toml.

    We only need the top-level bootstrap value (read from config.toml itself,
    like the Nix loader does), so a simple regex suffices — no full TOML parse.
    """
    if not config_toml.is_file():
        return ["configs"]

    text = config_toml.read_text(errors="replace")

    # Match:  extraConfigs = ["dir1", "dir2"]  (quotes optional, whitespace flexible)
    m = re.search(r"extraConfigs\s*=\s*\[(.*?)\]", text, re.DOTALL)
    if not m:
        return ["configs"]

    inner = m.group(1).strip()
    if not inner:
        return []

    # Split on commas, strip quotes/whitespace from each entry
    dirs = []
    for part in inner.split(","):
        part = part.strip().strip("\"'")
        if part:
            dirs.append(part)
    return dirs or ["configs"]


def collect_config_files(config_root: Path, extra_dirs: list[str]) -> list[Path]:
    """Collect all TOML files: config.toml + extraConfigs dirs (inc. dotfiles)."""
    files: list[Path] = []

    main = config_root / "config.toml"
    if main.is_file():
        files.append(main)

    for d in extra_dirs:
        dirpath = config_root / d
        if not dirpath.is_dir():
            continue
        for f in sorted(dirpath.iterdir()):
            if f.is_file() and f.suffix == ".toml":
                files.append(f)

    return files


# ---------------------------------------------------------------------------
# Migration engine
# ---------------------------------------------------------------------------

def migrate_content(content: str) -> tuple[str, dict[str, int]]:
    """Apply all renames to file content. Returns (new_content, {old_key: count})."""
    counts: dict[str, int] = {}
    new_lines: list[str] = []

    for line in content.splitlines(keepends=True):
        new_line = line
        for pattern, replacement in _PATTERNS:
            before = new_line
            new_line = pattern.sub(replacement, new_line)
            if new_line != before:
                counts[replacement] = counts.get(replacement, 0) + 1
        new_lines.append(new_line)

    return "".join(new_lines), counts


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def main() -> None:
    parser = argparse.ArgumentParser(
        description="Migrate IceDOS config keys from camelCase to kebab-case."
    )
    parser.add_argument(
        "--config-root",
        type=Path,
        default=None,
        help="Path to the IceDOS config root (default: auto-detect from CWD).",
    )
    parser.add_argument(
        "--apply",
        action="store_true",
        help="Apply changes (default is dry-run).",
    )
    args = parser.parse_args()

    dry_run = not args.apply
    config_root = find_config_root(args.config_root)
    extra_dirs = extract_extra_configs(config_root / "config.toml")
    files = collect_config_files(config_root, extra_dirs)

    print("IceDOS Config Casing Migration")
    print("=" * 40)
    print(f"Config root:      {config_root}")
    print(f"Extra config dirs: {extra_dirs}")
    print(f"Scanning {len(files)} file(s)...")
    print()

    if dry_run:
        print("DRY RUN — no files modified (use --apply to write)")
        print()

    total_replacements = 0
    files_changed = 0

    for filepath in files:
        rel = filepath.relative_to(config_root)
        try:
            content = filepath.read_text(errors="replace")
        except OSError as e:
            print(f"  skip {rel}: {e}", file=sys.stderr)
            continue

        new_content, counts = migrate_content(content)

        if not counts:
            continue

        files_changed += 1
        file_total = sum(counts.values())
        total_replacements += file_total

        print(f"{rel}:")
        for old_key, new_key in RENAMES.items():
            if new_key in counts:
                print(f"  {old_key} → {new_key} ({counts[new_key]})")
        print()

        if not dry_run:
            filepath.write_text(new_content)

    print("—" * 40)
    action = "would be changed" if dry_run else "changed"
    print(f"Summary: {len(files)} scanned, {files_changed} {action}, {total_replacements} replacements")


if __name__ == "__main__":
    main()
