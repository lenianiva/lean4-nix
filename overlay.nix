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
in {
  inherit readSrc readFromGit readRev tags;
}
