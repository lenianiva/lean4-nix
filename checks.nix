{ pkgs, ... }: let
  lake = import ./lake.nix { inherit pkgs; };
  example-direct = pkgs.lean.buildLeanPackage {
    name = "Example";
    roots = [ "Main" ];
    src = pkgs.lib.cleanSource ./templates/lib;
  };
  example-manifest = lake.mkPackage {
    src = ./templates/lib;
    roots = [ "Main" ];
  };
in {
  example-direct = example-direct.executable;
  example-manifest = example-manifest.executable;
}
