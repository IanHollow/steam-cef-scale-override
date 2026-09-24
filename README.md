# steam-cef-scale-override

[![OpenSSF Baseline: not assessed](https://img.shields.io/badge/OpenSSF%20Baseline-not%20assessed-lightgrey)](https://baseline.openssf.org/)
[![OpenSSF Scorecard](https://api.scorecard.dev/projects/github.com/IanHollow/steam-cef-scale-override/badge)](https://scorecard.dev/viewer/?uri=github.com/IanHollow/steam-cef-scale-override)
[![OpenSSF Best Practices: not enrolled](https://img.shields.io/badge/OpenSSF%20Best%20Practices-not%20enrolled-lightgrey)](https://www.bestpractices.dev/)

`steam-cef-scale-override` is a Linux library that adjusts the Steam desktop
client's UI scale under Wayland/XWayland. It is an opt-in workaround for blurry
text when the compositor leaves XWayland buffers unscaled.

## Install and use

On x86_64 Linux with Nix:

```console
nix build github:IanHollow/steam-cef-scale-override
```

The library is installed at `result/lib/libsteam-cef-scale-override.so`. Set
`STEAM_SCALE_FACTOR` to a number between `0.25` and `8.0`, and add the library
to the Steam launcher's `LD_PRELOAD` value so it reaches `steamwebhelper`. For
example, a launcher can set:

```sh
STEAM_SCALE_FACTOR=1.5
LD_PRELOAD="/path/to/libsteam-cef-scale-override.so${LD_PRELOAD:+:$LD_PRELOAD}"
export STEAM_SCALE_FACTOR LD_PRELOAD
```

Keep any libraries already in `LD_PRELOAD`. The
[`nixpkgs-personal`](https://github.com/nix-forge/nixpkgs-personal) package
provides the same library from a pinned source revision. The
[source releases](https://github.com/IanHollow/steam-cef-scale-override/releases)
contain versioned source archives, not prebuilt libraries.

## Scope and compatibility

The interposer calls Steam's exported `cef_set_force_device_scale_factor` after
a successful `cef_initialize` in `steamwebhelper`.

The library is deliberately inert unless all of these conditions hold:

- the executable basename is exactly `steamwebhelper`;
- `STEAM_SCALE_FACTOR` is present and is a finite number from `0.25` to `8.0`;
- CEF initialized successfully; and
- the Steam-provided scale function is available.

This is a temporary compatibility package, not an upstream Steam API. Remove
it when Valve's documented `STEAM_FORCE_DESKTOPUI_SCALING` or
`-forcedesktopscaling` path works again.

The implementation is derived from
[`steam-hidpi-shim`](https://github.com/katerinakosac51-creator/steam-hidpi-shim),
commit `f6651b1d6e85800885ea2b251ffc37c4e68df7e4`, under the included MIT
license. This version narrows process scope, removes the unnecessary
`cef_execute_process` hook and constructor, validates the complete scale
string, fails open, enables linker hardening, and adds behavioral tests.

Meson defines the library, mock targets, installation, and tests. The Nixpkgs
Meson and Ninja hooks provide an offline configure step, the Nix store prefix,
and build parallelism from `NIX_BUILD_CORES`. Package checks run the mock CEF
scenarios against the release library through `LD_PRELOAD` and against a separate
ASan/UBSan Meson build. The sanitizer executable, mock library, and interposer are
all instrumented. The sanitizer executable links the interposer before the mock
CEF library so the sanitizer runtime loads first.
Checks cover process scoping, valid boundary values, absent and malformed scales,
and initialization failure. Sanitizer diagnostics fail the build; only the
release library is installed.

Installed-library checks require ELF64, the interposer export, GNU_RELRO,
immediate binding, and an explicit non-executable GNU_STACK header. Production
compiler and linker settings remain separate from sanitizer instrumentation.

## Build and test

```sh
meson setup build -Dtests=true
meson compile -C build
meson test -C build --print-errorlogs
```

Meson 1.8 or newer, a C compiler, Ninja, and Bash are required. The Nix recipe is
`package.nix`. [`nixpkgs-personal`](https://github.com/nix-forge/nixpkgs-personal)
fetches a pinned revision of this repository and calls that recipe.

Run the complete local quality suite, including C static analysis, release and
sanitizer tests, shell checks, format checks, and ELF hardening checks, with:

```sh
nix develop --command bash Scripts/check-quality.sh
nix flake check
```

## Project health

Security and release expectations are documented in [SECURITY.md](SECURITY.md),
[SUPPORT.md](SUPPORT.md), and [security and release process](docs/security-and-releases.md).
Releases provide checksums and provenance for the source archives. The first
release is `v1.0.1`. The gray OpenSSF badges above indicate that this project
has not been enrolled or assessed by the Best Practices service; they do not
claim a Baseline level or a passing Best Practices status. SLSA claims, if any,
apply only to verified release archives, not to Nix builds or the repository.
