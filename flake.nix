{
  description = "Lean 4 Nix Flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    flake-parts,
    ...
  }:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-darwin"
        "x86_64-linux"
      ];

      flake =
        (import ./lib/overlay.nix)
        // {
          lake = import ./lib/lake.nix;
          templates = import ./templates;
        };

      perSystem = {
        system,
        pkgs,
        ...
      }: {
        _module.args.pkgs = import nixpkgs {
          inherit system;
          overlays = [(self.readToolchainFile ./templates/minimal/lean-toolchain)];
        };

        packages = {
          inherit (pkgs) lean;
        };

        checks = import ./checks.nix {inherit pkgs;};

        formatter = pkgs.alejandra;
      };
    };
}
