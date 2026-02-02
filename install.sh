#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_SRC="$SCRIPT_DIR/skills"
SKILLS_DST="$HOME/.claude/skills"

mkdir -p "$SKILLS_DST"

for skill_dir in "$SKILLS_SRC"/*/; do
    skill_name="$(basename "$skill_dir")"
    target="$SKILLS_DST/$skill_name"

    if [[ -L "$target" ]]; then
        echo "Updating: $skill_name"
        rm "$target"
    elif [[ -e "$target" ]]; then
        echo "Skipping: $skill_name (exists and is not a symlink)"
        continue
    else
        echo "Installing: $skill_name"
    fi

    ln -s "$skill_dir" "$target"
done

echo "Done."
