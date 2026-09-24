#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C
library="$1"
workdir=$(mktemp -d "${TMPDIR:-/tmp}/steam-cef-elf.XXXXXX")
trap 'rm -rf -- "$workdir"' EXIT

readelf -h "$library" >"$workdir/elf-header.log"
readelf -dW "$library" >"$workdir/elf-dynamic.log"
readelf -lW "$library" >"$workdir/elf-program-headers.log"
readelf -Ws "$library" >"$workdir/elf-symbols.log"

grep -Eq 'Class: +ELF64$' "$workdir/elf-header.log"
grep -Fq '(SONAME)' "$workdir/elf-dynamic.log"
grep -Eq 'GLOBAL +DEFAULT +[0-9]+ +cef_initialize$' "$workdir/elf-symbols.log"
if grep -Eq 'GLOBAL +DEFAULT +[0-9]+ +cef_execute_process$' "$workdir/elf-symbols.log"; then
  echo 'unexpected cef_execute_process interposition' >&2
  exit 1
fi

grep -Eq '^ +GNU_RELRO +' "$workdir/elf-program-headers.log"
# GNU linkers may encode immediate binding in DT_BIND_NOW, DT_FLAGS, or
# DT_FLAGS_1. Require the binding flag itself, not a substring in a dependency.
grep -Eq '\(BIND_NOW\)|\(FLAGS\).*\bBIND_NOW\b|\(FLAGS_1\).*\bNOW\b' "$workdir/elf-dynamic.log"
# Require an explicit stack header. The flags span one or two columns in
# readelf's wide output, so inspect all fields before the final alignment.
awk '
  $1 == "GNU_STACK" {
    found++
    for (i = 7; i < NF; i++) if ($i ~ /E/) executable = 1
  }
  END { exit !(found == 1 && !executable) }
' "$workdir/elf-program-headers.log"
