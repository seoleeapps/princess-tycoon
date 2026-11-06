#!/usr/bin/env bash
# 서명한 Google Play AAB를 만든다.
#   bash scripts/build_android.sh
# 업로드 키는 저장소 밖 ~/.config/seorilabs(카탈로그 app/princess-tycoon/google-play/upload-key)에서 읽고 값을 출력하지 않는다.
# 결과: build/android/princess-tycoon.aab, build/android/princess-tycoon.aab.sha256, build/android/export.log
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
godot_bin="${GODOT_BIN:-godot}"
env_file="${PRINCESS_TYCOON_KEYSTORE_ENV:-$HOME/.config/seorilabs/play-store/princess-tycoon-keystore.env}"
expected_cert="${PRINCESS_TYCOON_UPLOAD_CERT_SHA256:-BB:CF:E8:D7:B9:D2:65:61:7A:B8:41:4A:DC:26:58:79:50:84:A2:06:ED:11:E9:07:37:C8:3B:6A:39:E3:13:65}"
out_dir="$repo_root/build/android"
aab="$out_dir/princess-tycoon.aab"

if [ ! -f "$env_file" ]; then
  echo "[android] upload keystore env not found: $env_file" >&2
  exit 2
fi
set -a
# shellcheck disable=SC1090
. "$env_file"
set +a
export GODOT_ANDROID_KEYSTORE_RELEASE_PATH="$ANDROID_KEYSTORE_FILE"
export GODOT_ANDROID_KEYSTORE_RELEASE_USER="$ANDROID_KEYSTORE_ALIAS"
export GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD="$ANDROID_KEYSTORE_PASSWORD"
export JAVA_HOME="${JAVA_HOME:-/Library/Java/JavaVirtualMachines/temurin-17.jdk/Contents/Home}"
export ANDROID_HOME="${ANDROID_HOME:-$HOME/Library/Android/sdk}"

mkdir -p "$out_dir"
rm -f "$aab" "$aab.sha256"
log="$out_dir/export.log"
"$godot_bin" --headless --path "$repo_root/godot" --import >"$out_dir/import.log" 2>&1
set +e
"$godot_bin" --headless --path "$repo_root/godot" --install-android-build-template --export-release Android "$aab" >"$log" 2>&1
status=$?
set -e
errors="$(grep -E "^(SCRIPT ERROR|ERROR):|Parse Error|Failed to load script|BUILD FAILED" "$log" || true)"
if [ "$status" -ne 0 ] || [ -n "$errors" ] || [ ! -s "$aab" ]; then
  echo "[android] export failed (exit $status, log $log)" >&2
  [ -n "$errors" ] && echo "$errors" >&2
  exit 1
fi

keytool="$JAVA_HOME/bin/keytool"
# keytool은 AAB의 인증서를 출력하면서도 1을 돌려줄 수 있어 종료 코드 대신 출력한 지문을 비교한다.
actual_cert="$( ("$keytool" -printcert -jarfile "$aab" 2>/dev/null || true) | awk '/SHA256:/ {print $2; exit}')"
if [ "$actual_cert" != "$expected_cert" ]; then
  echo "[android] signing certificate mismatch: $actual_cert" >&2
  exit 1
fi
shasum -a 256 "$aab" | awk '{print $1}' >"$aab.sha256"
echo "[android] PASS $aab"
echo "[android] sha256 $(cat "$aab.sha256")"
echo "[android] upload certificate $actual_cert"
