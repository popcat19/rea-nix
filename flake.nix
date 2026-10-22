# Purpose: Export the REA package and its offline ELF integration check.
{
  description = "REA CLI and MCP with a pinned ELF Python runtime";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
      rea = pkgs.callPackage ./packaging/rea.nix { };
    in {
      packages.${system} = { inherit rea; default = rea; };
      apps.${system}.default = {
        type = "app";
        program = "${rea}/bin/rea";
      };
      checks.${system}.elf = pkgs.runCommand "rea-elf-smoke" {
        nativeBuildInputs = [ rea pkgs.gcc pkgs.python3 ];
      } ''
        export HOME="$TMPDIR/home"
        mkdir -p "$HOME"
        python3 ${./tests/elf-smoke.py} ${rea} ${./tests/elf-fixture.c}
        touch "$out"
      '';
    };
}
