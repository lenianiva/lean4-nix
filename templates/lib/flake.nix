{
  description = "Lean 4 Example Project";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
    flake-parts.url = "github:hercules-ci/flake-parts";
    lean4-nix.url = "github:lenianiva/lean4-nix";
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    flake-parts,
    lean4-nix,
    ...
  } : flake-parts.lib.mkFlake { inherit inputs; } {
    flake = {
    };
    systems = [
      "x86_64-linux"
      "x86_64-darwin"
      "aarch64-linux"
      "aarch64-darwin"
    ];
    perSystem = { system, pkgs, ... }: let
      leanPkgs = lean4-nix.packages.${system};
      project = leanPkgs.buildLeanPackage {
        name = "Example";
        roots = [ "Main" ];
        src = pkgs.lib.cleanSource ./.;
      };
    in rec {
      packages = {
        inherit (project) executable;
        default = project.executable;
      };
      devShells.default = pkgs.mkShell {
        buildInputs = [ leanPkgs.lean-all leanPkgs.lean ];
      };
    };
  };
}
