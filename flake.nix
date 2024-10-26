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
    flake = (import ./overlay.nix) // {
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
      overlay = import ./overlay.nix;
      pkgs = import nixpkgs {
        inherit system;
        #overlays = [ (overlay.readRev "dc2533473114eb8656439ff2b9335209784aa640") ];
        overlays = [ (overlay.readSrc lean) ];
      };
      checks = pkgs.callPackage ./checks.nix {};
    in {
      packages = {
        inherit (checks) example;
      };
    };
  };
}
