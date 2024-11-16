{
  description = "Lean 4 Nix Flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
    flake-parts.url = "github:hercules-ci/flake-parts";
    systems.url = "github:nix-systems/default";
  };

  outputs =
    inputs @ { self
    , nixpkgs
    , flake-parts
    , ...
    }: flake-parts.lib.mkFlake { inherit inputs; } {
      systems = import inputs.systems;

      flake = (import ./overlay.nix) // {
        lake = import ./lake.nix;
        templates = import ./templates;
      };

      perSystem = { system, pkgs, ... }:
        let
          overlay = import ./overlay.nix;
          pkgs = import nixpkgs {
            inherit system;
            overlays = [ (overlay.readToolchainFile ./templates/minimal/lean-toolchain) ];
          };
          checks = import ./checks.nix { inherit pkgs; };
        in
        {
          packages = {
            inherit (pkgs.lean) leanshared lean leanc lean-all lake;
          };
          inherit checks;
          formatter = pkgs.nixpkgs-fmt;
        };
    };
}
