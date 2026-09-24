#!/usr/bin/env bash
set -euo pipefail

cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.."

nixfmt --check flake.nix package.nix
shellcheck --shell=bash --severity=style Scripts/check-quality.sh check-elf.sh check-mock.sh
shfmt -d -i 2 Scripts/check-quality.sh check-elf.sh check-mock.sh
clang-format --dry-run --Werror steam-cef-scale-override.c test-helper.c test-libcef.c
clang-tidy steam-cef-scale-override.c test-helper.c test-libcef.c \
  --checks='-*,clang-analyzer-core.*,clang-analyzer-deadcode.*,clang-analyzer-unix.*,bugprone-branch-clone,bugprone-sizeof-expression' \
  --warnings-as-errors='*' \
  -- -std=c11 -Wall -Wextra -Werror

build_dir=$(mktemp -d "${TMPDIR:-/tmp}/steam-cef-quality.XXXXXX")
trap 'rm -rf -- "$build_dir"' EXIT

meson setup "$build_dir/release" . --buildtype=release -Dtests=true
meson compile -C "$build_dir/release"
meson test -C "$build_dir/release" --print-errorlogs
bash check-elf.sh "$build_dir/release/libsteam-cef-scale-override.so"

meson setup "$build_dir/sanitized" . --buildtype=debugoptimized \
  -Db_asneeded=false -Db_lundef=false -Db_sanitize=address,undefined -Dtests=true
meson compile -C "$build_dir/sanitized"
meson test -C "$build_dir/sanitized" --print-errorlogs
