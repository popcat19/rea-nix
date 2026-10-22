# REA Nix package

This flake packages the released `rea-agents` 6.7.0 npm artifact at upstream
commit `27dc42d10249f0410904a75c0997842eb03b931c`. The package includes the
CLI and MCP server from npm, plus a wrapped Python environment for REA's
Linux x86_64 offline ELF layout operation. ELF support is the only bundled
analysis provider:

- pwntools 4.15.0
- pyelftools 0.33
- unicorn 2.1.2

The wrapper sets `REA_PWNTOOLS_PYTHON` to this environment. Other REA
providers remain caller supplied and are not bundled by this package.

## Use

```sh
nix run git+https://dawn.wine/popcat19/rea-nix.git -- --help
nix run . -- inspect-binary-layout ./program
nix build .#rea
nix flake check
```

The flake check compiles a small ELF and runs the installed REA command against
it. The npm lockfile and Nix hashes pin the dependency inputs.

## Updating

Forgejo checks the latest stable npm release every Monday and on manual dispatch.
It provisions Nix with a pinned action and uses tools from the locked flake dev
shell. The updater refreshes the npm lock, Nix dependency hash and package version,
then runs the sandboxed CLI and MCP ELF checks. Only validated updates are
committed and pushed to main using the built-in job token. Failed candidates
restore the original packaging files. Unchanged versions do not mutate files.

Run a candidate locally with:

```sh
nix develop --command scripts/update.sh 6.7.0
```

The Python ABI versions remain deliberately pinned. A future REA release that
requires different versions must receive a reviewed Python override update;
failed smoke checks prevent automatic publication. Optional npm dependencies
and install scripts are disabled, including Frida and native PTY setup. Ghidra,
Hopper, browser automation and other backends are not validated or bundled.
The workflow requires an available dawn.wine runner with the `docker` label
and permission for the built-in job token to push to main.
