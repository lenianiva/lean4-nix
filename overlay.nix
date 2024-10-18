{ lean } : final: pkgs: let
  lean-packages = pkgs.callPackage ./packages.nix { src = lean; };
in {
  lean = lean-packages;
}
