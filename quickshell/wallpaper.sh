#!/usr/bin/env bash
set -euo pipefail

# Quickshell-friendly wallpaper helper.
# Usage: wallpaper.sh "/path/to/wallpaper"

WALLPAPER="${1:-}"

if [[ -z "$WALLPAPER" ]]; then
    printf 'Usage: %s <wallpaper>\n' "${0##*/}" >&2
    exit 2
fi

if [[ ! -f "$WALLPAPER" ]]; then
    printf 'Wallpaper not found: %s\n' "$WALLPAPER" >&2
    exit 1
fi

# Keep the transition choice deterministic per invocation without spawning
# an extra date process.
TYPES=("wave" "any")
SELECTED_TYPE="${TYPES[RANDOM % ${#TYPES[@]}]}"

# Run awww first. exec avoids leaving an unnecessary shell process around.
awww img "$WALLPAPER" \
    --transition-duration 1 \
    --transition-fps 165 \
    --transition-bezier 0.2,0.4,0.8,0.6 \
    --transition-type "$SELECTED_TYPE" \
    --transition-wave 70,50 \
    --transition-angle "$((1 + RANDOM % 361))"

# Apply the glass effect after the wallpaper has been changed.
iris \
    --image "$WALLPAPER" \
    --glass \
    --dark 1
