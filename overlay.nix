let
  manifests = import ./manifests;
  readSrc = { src, bootstrap } : final: prev: prev // rec {
    lean = (prev.callPackage ./lib/packages.nix { inherit src bootstrap; }) // {
      lake = lean.Lake-Main.executable;
    };
  };
  readFromGit = { args, bootstrap }: readSrc { src = builtins.fetchGit args; inherit bootstrap; };
  readRev = { rev, bootstrap, tag }: readFromGit {
    args = {
      url = "https://github.com/leanprover/lean4.git";
      shallow = true;
      ref = "refs/tags/${tag}";
      inherit rev;
    };
    inherit bootstrap;
  };
  tags = builtins.mapAttrs (tag: manifest: readRev { inherit (manifest) tag rev bootstrap; }) manifests;
  readToolchain = toolchain : builtins.addErrorContext "Only leanprover/lean4:{tag} toolchains are supported" (let
    matches = builtins.match "^[[:space:]]*leanprover/lean4:([a-zA-Z0-9\\-\\.]+)[[:space:]]*$" toolchain;
    tag = builtins.head matches;
  in
    builtins.getAttr tag tags);
  readToolchainFile = toolchainFile : readToolchain (builtins.readFile toolchainFile);
in {
  inherit readSrc readFromGit readRev tags readToolchain readToolchainFile;
}
