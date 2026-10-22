# Purpose: Match the exact Python package versions required by REA's ELF bridge.
{ pkgs }:
let
  unicorn = pkgs.unicorn.overrideAttrs {
    version = "2.1.2";
    src = pkgs.fetchFromGitHub {
      owner = "unicorn-engine";
      repo = "unicorn";
      tag = "2.1.2";
      hash = "sha256-qA84xBztyWmt/rUExhhZMkQzvDPx0UE9MAIPG/Su3iE=";
    };
  };
  python = pkgs.python313.override {
    packageOverrides = final: prev: {
      unicorn = (prev.unicorn.override { inherit unicorn; }).overridePythonAttrs (old: {
        postPatch = (old.postPatch or "") + ''
          substituteInPlace pyproject.toml \
            --replace-fail ', "versioningit"' "" \
            --replace-fail 'dynamic = ["version"]' 'version = "2.1.2"' \
            --replace-fail '[tool.versioningit]' ""
        '';
      });
      pyelftools = prev.pyelftools.overridePythonAttrs {
        version = "0.33";
        src = pkgs.fetchFromGitHub {
          owner = "eliben";
          repo = "pyelftools";
          tag = "v0.33";
          hash = "sha256-NqF5A6PRl4uncwNS9j44fIV7ovlljiucvV2Msv0LK/w=";
        };
      };
    };
  };
in
python.withPackages (ps: [
  ps.pwntools
  ps.pyelftools
  ps.unicorn
])
