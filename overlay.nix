let
  manifests = import ./manifests;
  readSrc = src: final: prev: prev // {
    lean = prev.callPackage ./lib/packages.nix { inherit src; };
  };
  readFromGit = args: readSrc (builtins.fetchGit args);
  readRev = rev: readFromGit {
    url = "https://github.com/leanprover/lean4.git";
    inherit rev;
  };
  tags = builtins.mapAttrs (tag: manifest: readRev manifest.rev) manifests;
  readToolchain = toolchainFile : let
      toolchain = builtins.readFile toolchainFile;
      matches = builtins.match "^leanprover/lean4:(.*)$" toolchain;
      tag = builtins.head matches;
    in
      builtins.getAttr tag tags;
in {
  inherit readSrc readFromGit readRev tags readToolchain;
}
