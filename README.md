# REA Nix package

This flake packages the released `rea-agents` 6.7.0 npm artifact at upstream
commit `27dc42d10249f0410904a75c0997842eb03b931c`. The package includes the
CLI and MCP server from npm, plus a wrapped Python environment for REA's
Linux x86_64 offline ELF layout operation:

- pwntools 4.15.0
- pyelftools 0.33
- unicorn 2.1.2

The wrapper sets `REA_PWNTOOLS_PYTHON` to this environment. Other REA
providers remain caller supplied and are not bundled by this package.

## Use

```sh
nix run github:dawn-wine/rea-nix -- --help
nix run . -- inspect-binary-layout ./program
nix build .#rea
nix flake check
```

The flake check compiles a small ELF and runs the installed REA command against
it. The npm lockfile and Nix hashes pin the dependency inputs.

## Updating

Forgejo's scheduled updater runs `scripts/update.sh`. It creates a temporary
candidate, refreshes the npm lockfile, evaluates the flake, builds the package,
and runs the ELF smoke check before creating an update commit. Publishing still
requires the repository's normal review process.
