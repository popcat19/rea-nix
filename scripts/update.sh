#!/usr/bin/env bash
# Purpose: Refresh the pinned REA npm release after validating a candidate.
set -euo pipefail
version="${1:?usage: scripts/update.sh VERSION}"
repo_root="$(git rev-parse --show-toplevel)"
cd "$repo_root"
workdir="$(mktemp -d)"
trap 'rm -rf "$workdir"' EXIT
jq --arg version "$version" '.version = $version | .dependencies["rea-agents"] = $version' packaging/package.json > "$workdir/package.json"
cp packaging/package-lock.json "$workdir/package-lock.json"
npm install --package-lock-only --ignore-scripts --prefix "$workdir"
cp "$workdir/package.json" packaging/package.json
cp "$workdir/package-lock.json" packaging/package-lock.json
hash="$(nix run nixpkgs#prefetch-npm-deps -- packaging/package-lock.json)"
sed -i "s#npmDepsHash = \".*\"#npmDepsHash = \"$hash\"#" packaging/rea.nix
nix flake check
nix build .#rea
