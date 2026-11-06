#!/usr/bin/env bash
# 실제 홈 화면의 활동 fixture에서 8종 전체 루프와 좌표 입력을 확인한다.
set -euo pipefail
repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
godot_bin="${GODOT_BIN:-godot}"
out_root="${ANIMATION_OUT_DIR:-$repo_root/build/pixel-animations/loops}"
viewports=(${ANIMATION_VIEWPORTS:-390x844 430x932 720x1280})
failed=0
for viewport in "${viewports[@]}"; do
  out_dir="$out_root/$viewport"
  mkdir -p "$out_dir"
  status=0
  "$godot_bin" --fixed-fps 60 --path "$repo_root/godot" --script res://tests/pixel_animation_capture.gd -- \
    "--viewport=$viewport" "--out=$out_dir" >"$out_dir/run.log" 2>&1 || status=$?
  if [ "$status" -ne 0 ] || rg -q '^(SCRIPT ERROR|ERROR):|Parse Error|Failed to load script|Could not load resource|No loader found for resource' "$out_dir/run.log"; then
    echo "[animation] $viewport FAIL exit=$status log=$out_dir/run.log" >&2
    failed=1
  else
    echo "[animation] $viewport PASS ($out_dir/journey.json)"
  fi
done
exit "$failed"
