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
      }: let
        toolchain-file = ./templates/minimal/lean-toolchain;
        pkgs = import nixpkgs {
          inherit system;
          overlays = [(self.readToolchainFile toolchain-file)];
        };
        pkgs-built = import nixpkgs {
          inherit system;
          overlays = [
            (self.readToolchainFile {
              toolchain = toolchain-file;
              binary = false;
            })
          ];
        };
        lake2nix = pkgs.callPackage self.lake {};
      in {
        packages = {
          lean-bin = pkgs.lean;
          inherit (pkgs-built) lean;
        };
        devShells.default = pkgs.mkShell {
          buildInputs = [pkgs.pre-commit (pkgs.callPackage ./lib/toolchain.nix {}).toolchain-fetch];
        };

        checks = (import ./checks.nix) {inherit pkgs lake2nix pkgs-built;};

        formatter = pkgs.alejandra;
      };
    };
}
