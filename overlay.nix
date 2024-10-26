let
  readSrc = src: final: prev: prev // {
    lean = prev.callPackage ./packages.nix { inherit src; };
  };
  readFromGit = args: readSrc (builtins.fetchGit args);
  readRev = rev: readFromGit {
    url = "https://github.com/leanprover/lean4.git";
    inherit rev;
  };
in {
  inherit readSrc readFromGit readRev;
}
