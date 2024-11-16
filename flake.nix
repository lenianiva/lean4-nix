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
    , systems
    }: flake-parts.lib.mkFlake { inherit inputs; } {
      systems = import systems;

      flake = (import ./overlay.nix) // {
        lake = import ./lake.nix;
        templates = import ./templates;
      };

      perSystem = { pkgs, system, ... }: {
        _module.args.pkgs = import nixpkgs {
          inherit system;
          overlays = [ (self.readToolchainFile ./templates/minimal/lean-toolchain) ];
        };

        checks = import ./checks.nix { inherit pkgs; };

        formatter = pkgs.nixpkgs-fmt;

        packages = {
          inherit (pkgs.lean) leanshared lean leanc lean-all lake;
        };
      };
    };
}
