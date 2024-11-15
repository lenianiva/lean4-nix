{
  description = "Lean 4 Nix Flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    flake-parts,
    ...
  } : flake-parts.lib.mkFlake { inherit inputs; } {
    flake = (import ./overlay.nix) // {
      lake = import ./lake.nix;
      templates = import ./templates;
    };
    systems = [
      "x86_64-linux"
      "x86_64-darwin"
      "aarch64-linux"
      "aarch64-darwin"
    ];
    perSystem = { system, pkgs, ... }: let
      overlay = import ./overlay.nix;
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ (overlay.readToolchainFile ./templates/minimal/lean-toolchain) ];
      };
      checks = import ./checks.nix { inherit pkgs; };
    in {
      packages = {
        inherit (pkgs.lean) leanshared lean leanc lean-all;
        lake = pkgs.lean.Lake-Main.executable;
      };
      inherit checks;
    };
  };
}
