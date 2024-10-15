{ lean-packages, pkgs, ... }: let
  example = lean-packages.buildLeanPackage {
    name = "Example";
    roots = [ "Main" ];
    src = pkgs.lib.cleanSource ./templates/lib;
  };
in {
  example = example.executable;
}
