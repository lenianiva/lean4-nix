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
  readToolchain = toolchain : builtins.addErrorContext "Only leanprover/lean4:{tag} toolchains are supported" (let
    matches = builtins.match "^[[:space:]]*leanprover/lean4:([a-zA-Z0-9\\-\\.]+)[[:space:]]*$" toolchain;
    tag = builtins.head matches;
  in
    builtins.getAttr tag tags);
  readToolchainFile = toolchainFile : readToolchain (builtins.readFile toolchainFile);
in {
  inherit readSrc readFromGit readRev tags readToolchain readToolchainFile;
}
