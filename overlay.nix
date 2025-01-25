{lib}: let
  manifests = let
    dir = ./manifests;
  in
    lib.listToAttrs (map
      (fn: {
        name = lib.removeSuffix ".nix" fn;
        value = import (dir + "/${fn}");
      })
      (lib.attrNames (lib.readDir dir)));

  readSrc = {
    src,
    bootstrap,
  }: final: prev:
    prev
    // rec {
      lean =
        (prev.callPackage ./lib/packages.nix {inherit src bootstrap;})
        // {
          lake = lean.Lake-Main.executable;
        };
    };
  readFromGit = {
    args,
    bootstrap,
  }:
    readSrc {
      src = lib.fetchGit args;
      inherit bootstrap;
    };
  readRev = {
    rev,
    bootstrap,
    tag,
  }:
    readFromGit {
      args = {
        url = "https://github.com/leanprover/lean4.git";
        shallow = true;
        ref = "refs/tags/${tag}";
        inherit rev;
      };
      inherit bootstrap;
    };
  tags =
    lib.mapAttrs (
      tag: manifest:
        if lib.match ".*-bin$" tag != null
        then final: prev: prev // {lean = prev.callPackage manifest.bootstrap {};}
        else readRev {inherit (manifest) tag rev bootstrap;}
    )
    manifests;

  readToolchain = toolchain:
    lib.addErrorContext "Only leanprover/lean4:{tag}[-bin] toolchains are supported" (let
      matches = lib.match "^[[:space:]]*leanprover/lean4:([a-zA-Z0-9\\-\\.]+)(-bin)?[[:space:]]*$" toolchain;
      tag = lib.head matches;
      bin = lib.length matches > 1 && lib.elemAt matches 1 == "-bin";
    in
      lib.getAttr
      (
        if bin
        then "${tag}-bin"
        else tag
      )
      tags);

  readToolchainFile = toolchainFile: readToolchain (lib.readFile toolchainFile);
in {
  inherit readSrc readFromGit readRev tags readToolchain readToolchainFile;
}
