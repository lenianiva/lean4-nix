let
  manifests = import ../manifests;
  readSrc = {
    src,
    bootstrap,
    buildLeanPackage ? null,
  }: final: prev:
    prev
    // rec {
      lean =
        (prev.callPackage ./packages.nix {inherit src bootstrap buildLeanPackage;})
        // {
          lake = lean.Lake-Main.executable;
        };
    };
  readFromGit = {
    args,
    bootstrap,
    buildLeanPackage ? null,
  }:
    readSrc {
      src = builtins.fetchGit args;
      inherit bootstrap buildLeanPackage;
    };
  readRev = {
    rev,
    bootstrap,
    buildLeanPackage ? null,
    tag,
    toolchain,
  }:
    readFromGit {
      args = {
        url = "https://github.com/leanprover/lean4.git";
        shallow = true;
        ref = "refs/tags/${tag}";
        inherit rev;
      };
      inherit bootstrap buildLeanPackage;
    };
  # Fetches a binary Lean
  readBinaryToolchain = manifest: final: prev:
    prev
    // {
      lean = (prev.callPackage ./toolchain.nix {}).fetchBinaryLean manifest;
    };
  tags =
    builtins.mapAttrs (tag: manifest: {
      lean = readRev manifest;
      lean-bin = readBinaryToolchain manifest;
    })
    manifests;
  readToolchain = toolchain: let
    config =
      if builtins.isString toolchain
      then {
        inherit toolchain;
        binary = true;
      }
      else toolchain;
    tag = builtins.addErrorContext "Only leanprover/lean4:{tag} toolchains are supported" (
      builtins.head (builtins.match "^[[:space:]]*leanprover/lean4:([a-zA-Z0-9\\-\\.]+)[[:space:]]*$" config.toolchain)
    );
    overlay-set = builtins.getAttr tag tags;
  in
    if config.binary
    then overlay-set.lean-bin
    else overlay-set.lean;
  readToolchainFile = toolchainPath: let
    config =
      if builtins.isPath toolchainPath
      then {
        toolchain = builtins.readFile toolchainPath;
        binary = true;
      }
      else {
        toolchain = builtins.readFile toolchainPath.toolchain;
        inherit (toolchainPath) binary;
      };
  in
    readToolchain config;
in {
  inherit readSrc readFromGit readRev tags readToolchain readToolchainFile;
}
