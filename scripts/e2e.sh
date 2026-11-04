#!/usr/bin/env bash
# 실제 main.tscn을 화면 좌표 입력으로 조작하는 E2E 여정을 3개 viewport에서 실행한다.
#   bash scripts/e2e.sh             # headless 게이트
#   bash scripts/e2e.sh --capture   # 렌더링 모드, 장면별 PNG 저장(창이 잠깐 뜬다)
# 결과: build/e2e/<WxH>/journey.json, 캡처 PNG, 실행 로그
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
godot_bin="${GODOT_BIN:-godot}"
out_root="${E2E_OUT_DIR:-$repo_root/build/e2e}"
viewports=(${E2E_VIEWPORTS:-390x844 430x932 720x1280})
capture=0
if [ "${1:-}" = "--capture" ]; then
  capture=1
fi

failed=0
for viewport in "${viewports[@]}"; do
  out_dir="$out_root/$viewport"
  rm -rf "$out_dir"
  mkdir -p "$out_dir"
  log_file="$out_dir/journey.log"
  args=(--fixed-fps 60 --path "$repo_root/godot" --script res://tests/e2e/journey.gd -- --out "$out_dir" "--viewport=$viewport")
  if [ "$capture" -eq 1 ]; then
    args+=(--capture)
  else
    args=(--headless "${args[@]}")
  fi
  set +e
  "$godot_bin" "${args[@]}" >"$log_file" 2>&1
  status=$?
  set -e
  # E2E 단계 실패는 journey.json에서 판정하고, 그 밖의 엔진·스크립트 오류는 로그에서 찾는다.
  engine_errors="$(grep -E "^(SCRIPT ERROR|ERROR):|Parse Error|Failed to load script|Could not load resource|No loader found for resource" "$log_file" | grep -v "E2E step failed" || true)"
  if [ "$status" -ne 0 ] || [ -n "$engine_errors" ]; then
    echo "[e2e] $viewport FAILED (exit $status, log $log_file)" >&2
    grep -E "E2E step failed" "$log_file" >&2 || true
    [ -n "$engine_errors" ] && echo "$engine_errors" >&2
    failed=1
  else
    echo "[e2e] $viewport PASS ($out_dir/journey.json)"
  fi
done

exit "$failed"
