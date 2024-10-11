{
  description = "Lean 4 Nix Flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
    flake-parts.url = "github:hercules-ci/flake-parts";
    lean = {
      url = "github:leanprover/lean4?ref=v4.12.0";
      flake = false;
    };
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    flake-parts,
    lean,
    ...
  } : flake-parts.lib.mkFlake { inherit inputs; } {
    flake = {
      templates = {
        lib = {
          path = ./templates/lib;
          description = "Example Lean Project";
        };
        default = self.templates.lib;
      };
    };
    systems = [
      "x86_64-linux"
      "x86_64-darwin"
      "aarch64-linux"
      "aarch64-darwin"
    ];
    perSystem = { system, pkgs, ... }: let
      lean-packages = pkgs.callPackage (./packages.nix) { src = lean; };
    in rec {
      packages = lean-packages;
    };
  };
}
