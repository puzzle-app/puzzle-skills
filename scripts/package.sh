#!/usr/bin/env bash
# Package every skill in skills/ as a .skill file (a zip of the skill folder) into dist/.
# Usage: scripts/package.sh            -> dist/<name>.skill for each skill
#        scripts/package.sh read-the-map -> just that one
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p dist
if [ $# -gt 0 ]; then names=("$@"); else names=($(ls skills)); fi
for n in "${names[@]}"; do
  [ -f "skills/$n/SKILL.md" ] || { echo "no SKILL.md in skills/$n" >&2; exit 1; }
  rm -f "dist/$n.skill"
  (cd skills && zip -q -X -r "../dist/$n.skill" "$n" -x '*.DS_Store')
  echo "dist/$n.skill"
done
