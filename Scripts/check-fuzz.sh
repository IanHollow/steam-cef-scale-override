#!/usr/bin/env bash
set -euo pipefail

cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.."

scratch_dir=$(mktemp -d "${TMPDIR:-/tmp}/steam-cef-fuzz.XXXXXX")
trap 'rm -rf -- "$scratch_dir"' EXIT
mkdir "$scratch_dir/corpus"
cp -- fuzz/corpus/scale/* "$scratch_dir/corpus/"

clang -std=c11 -g -O1 -fno-omit-frame-pointer \
  -fsanitize=fuzzer,address,undefined \
  fuzz-scale.c -ldl -lm -o "$scratch_dir/fuzz-scale"

"$scratch_dir/fuzz-scale" "$scratch_dir/corpus" \
  -runs="${STEAM_CEF_FUZZ_RUNS:-5000}" -max_len=128 \
  -artifact_prefix="$scratch_dir/" -print_final_stats=1
