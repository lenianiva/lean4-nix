{
  pkgs,
  lib,
  lean,
  lake2nix,
  ...
}: let
  minimal-direct = lean.buildLeanPackage {
    name = "Example";
    roots = ["Main"];
    src = lib.cleanSource ./templates/minimal;
  };
  minimal-manifest = lake2nix.mkPackage {
    src = lib.cleanSource ./templates/minimal;
    roots = ["Main"];
  };
  dependency-manifest = lake2nix.mkPackage {
    src = lib.cleanSource ./templates/dependency;
    roots = ["Example"];
  };
  # Try to generate overlays...
  overlays = import ./lib/overlay.nix;
in {
  inherit (pkgs) lean;
  minimal-direct = minimal-direct.executable;
  minimal-manifest = minimal-manifest.executable;
  dependency-manifest = dependency-manifest.executable;
}
