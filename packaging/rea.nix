# Purpose: Install the published npm runtime without rebuilding upstream dist.
{ pkgs, lib, buildNpmPackage, nodejs_24, makeWrapper, binutils, file }:
let
  elfPython = import ./elf-python.nix { inherit pkgs; };
in buildNpmPackage {
  pname = "rea-agents";
  version = "6.7.0";
  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [ ./package.json ./package-lock.json ];
  };
  nodejs = nodejs_24;
  npmDepsHash = "sha256-mR3Sv+LI5b91IdbuXi4L80dFx6KHeNy3fr355xWuMMY=";
  npmFlags = [ "--ignore-scripts" "--omit=dev" "--omit=optional" ];
  dontNpmBuild = true;
  nativeBuildInputs = [ makeWrapper ];
  installPhase = ''
    runHook preInstall
    mkdir -p "$out/lib/rea" "$out/bin"
    cp -r node_modules "$out/lib/rea/"
    makeWrapper ${nodejs_24}/bin/node "$out/bin/rea" \
      --add-flags "$out/lib/rea/node_modules/rea-agents/scripts/rea.mjs" \
      --set REA_PWNTOOLS_PYTHON ${elfPython}/bin/python3 \
      --prefix PATH : ${lib.makeBinPath [ binutils file ]}
    ln -s rea "$out/bin/rea-agents"
    runHook postInstall
  '';
  passthru = { inherit elfPython; };
  meta = {
    description = "Reverse engineering CLI and MCP server with offline ELF support";
    homepage = "https://github.com/morluto/rea";
    license = lib.licenses.mit;
    mainProgram = "rea";
    platforms = [ "x86_64-linux" ];
  };
}
