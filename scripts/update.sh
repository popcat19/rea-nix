#!/usr/bin/env bash
# Purpose: Refresh the pinned REA npm release after validating a candidate.
set -euo pipefail
version="${1:?usage: scripts/update.sh VERSION}"
if [[ ! "$version" =~ ^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$ ]]; then
  printf 'invalid semver: %s\n' "$version" >&2
  exit 2
fi
repo_root="$(git rev-parse --show-toplevel)"
cd "$repo_root"
current="$(jq -r '.version' packaging/package.json)"
if [[ "$version" == "$current" ]]; then
  printf 'rea-agents %s is already pinned\n' "$version"
  exit 0
fi
workdir="$(mktemp -d)"
backup="$(mktemp -d)"
restore() {
  if [[ "${validated:-0}" != 1 ]]; then
    cp "$backup/package.json" packaging/package.json
    cp "$backup/package-lock.json" packaging/package-lock.json
    cp "$backup/rea.nix" packaging/rea.nix
  fi
  rm -rf "$workdir" "$backup"
}
trap restore EXIT
cp packaging/package.json "$backup/package.json"
cp packaging/package-lock.json "$backup/package-lock.json"
cp packaging/rea.nix "$backup/rea.nix"
jq --arg version "$version" '.version = $version | .dependencies["rea-agents"] = $version' packaging/package.json > "$workdir/package.json"
cp packaging/package-lock.json "$workdir/package-lock.json"
npm install --package-lock-only --ignore-scripts --prefix "$workdir"
cp "$workdir/package.json" packaging/package.json
cp "$workdir/package-lock.json" packaging/package-lock.json
hash="$(prefetch-npm-deps packaging/package-lock.json)"
sed -i "s#npmDepsHash = \".*\"#npmDepsHash = \"$hash\"#" packaging/rea.nix
python3 - "$version" packaging/rea.nix <<'PY'
import pathlib
import re
import sys
path = pathlib.Path(sys.argv[2])
text = path.read_text()
updated, count = re.subn(r'version = "[^"]+";', f'version = "{sys.argv[1]}";', text, count=1)
if count != 1:
    raise SystemExit("packaging/rea.nix version field not found")
path.write_text(updated)
PY
nix flake check
nix build .#rea
validated=1
