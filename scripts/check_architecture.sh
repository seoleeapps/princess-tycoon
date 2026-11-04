#!/usr/bin/env bash
set -euo pipefail

required_paths=(
  godot/project.godot
  godot/export_presets.cfg
  godot/scenes/main.tscn
  godot/src/core
  godot/src/ui
  godot/src/ui/activity_progress_ring.gd
  godot/src/ui/pixel/pixel_theme.gd
  godot/src/ui/pixel/pixel_tokens.gd
  godot/src/ui/pixel/pixel_trainee_view.gd
  godot/src/ui/pixel/trainee_compositor.gd
  godot/src/ui/result_feedback_layer.gd
  godot/src/ports
  godot/tests
  godot/tests/render_capture.gd
  godot/assets/fonts/NeoDunggeunmo-Regular.ttf
  godot/assets/fonts/OFL-NeoDunggeunmo.txt
  godot/assets/fonts/Galmuri11-Bold.ttf
  godot/assets/fonts/OFL-Galmuri.txt
  godot/assets/pixel/ui/skins.json
  godot/assets/pixel/sprites/trainee.json
)

for path in "${required_paths[@]}"; do
  test -e "$path" || { echo "Missing required runtime path: $path" >&2; exit 1; }
done

forbidden='res://src/ui|CanvasItem|Control|Node2D|Firebase|Firestore|AdMob|JavaScriptBridge'
if rg -n "$forbidden" godot/src/core --glob '*.gd'; then
  echo "Core architecture boundary violation." >&2
  exit 1
fi

if rg -n 'res://extract|\.\./extract' godot --glob '*.gd' --glob '*.tscn' --glob '*.tres' --glob '*.json'; then
  echo "Runtime references research-only extract assets." >&2
  exit 1
fi

rg -q '^window/size/viewport_width=390$' godot/project.godot
rg -q '^window/size/viewport_height=844$' godot/project.godot
rg -q '^window/stretch/mode="canvas_items"$' godot/project.godot
rg -q '^window/stretch/aspect="keep"$' godot/project.godot
rg -q '^window/handheld/orientation=1$' godot/project.godot
rg -q '^renderer/rendering_method="gl_compatibility"$' godot/project.godot
# 도트 화면: nearest 필터와 2D 픽셀 스냅
rg -q '^textures/canvas_textures/default_texture_filter=0$' godot/project.godot
rg -q '^2d/snap/snap_2d_transforms_to_pixel=true$' godot/project.godot
rg -q '^2d/snap/snap_2d_vertices_to_pixel=true$' godot/project.godot

for port in local_analytics_port noop_ad_port noop_iap_port synth_audio_port; do
  test -s "godot/src/ports/${port}.gd" || { echo "Missing runtime port: $port" >&2; exit 1; }
done

echo "Architecture boundary passed: core isolation, portrait runtime, licensed font, platform ports."
