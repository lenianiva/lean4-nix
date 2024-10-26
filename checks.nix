{ pkgs, ... }: let
  lake = import ./lake.nix { inherit pkgs; };
  minimal-direct = pkgs.lean.buildLeanPackage {
    name = "Example";
    roots = [ "Main" ];
    src = pkgs.lib.cleanSource ./templates/minimal;
  };
  minimal-manifest = lake.mkPackage {
    src = ./templates/minimal;
    roots = [ "Main" ];
  };
  dependency-manifest = lake.mkPackage {
    src = ./templates/dependency;
    roots = [ "Example" ];
  };
in {
  minimal-direct = minimal-direct.executable;
  minimal-manifest = minimal-manifest.executable;
  dependency-manifest = dependency-manifest.executable;
}
