let
  manifests = import ../manifests;
  readSrc = args @ {
    src,
    bootstrap,
    buildLeanPackage ? null,
    overlay ? final: prev: {},
    ...
  }: final: prev:
    (args.overlay final prev)
    // rec {
      lean =
        (final.callPackage ./packages.nix {inherit src bootstrap buildLeanPackage;})
        // {
          lake = lean.Lake-Main.executable;
        };
    };
  readFromGit = {
    args,
    bootstrap,
    overlay ? final: prev: {},
    buildLeanPackage ? null,
  }:
    readSrc {
      src = builtins.fetchGit args;
      inherit bootstrap buildLeanPackage overlay;
    };
  readRev = {
    rev,
    bootstrap,
    buildLeanPackage ? null,
    overlay ? final: prev: {},
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
      inherit bootstrap buildLeanPackage overlay;
    };
  # Fetches a binary Lean
  readBinaryToolchain = manifest @ {overlay ? final: prev: {}, ...}: final: prev:
    (overlay final prev)
    // {
      lean = (final.callPackage ./toolchain.nix {}).fetchBinaryLean manifest;
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
    tag = builtins.addErrorContext "Only leanprover/lean4:{tag} toolchains for stable versions are supported." (
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
