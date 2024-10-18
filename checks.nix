{ pkgs, ... }: let
  example = pkgs.lean.buildLeanPackage {
    name = "Example";
    roots = [ "Main" ];
    src = pkgs.lib.cleanSource ./templates/lib;
  };
in {
  example = example.executable;
}
