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
        # With built toolchain
        pkgs-bin = import nixpkgs {
          inherit system;
          overlays = [(self.readToolchainFile toolchain-file)];
        };
        # With binary toolchain
        pkgs = import nixpkgs {
          inherit system;
          overlays = [
            (self.readToolchainFile {
              toolchain = toolchain-file;
              binary = false;
            })
          ];
        };
        lake2nix-bin = pkgs-bin.callPackage self.lake {};
      in {
        packages = {
          lean-bin = pkgs-bin.lean;
          inherit (pkgs) lean;
          inherit (pkgs.lean) cacheRoots;
          inherit (pkgs.callPackage ./lib/toolchain.nix {}) toolchain-fetch;
        };
        devShells.default = pkgs.mkShell {
          buildInputs = [pkgs.pre-commit];
        };

        checks = (import ./checks.nix) {inherit pkgs-bin lake2nix-bin pkgs;};

        formatter = pkgs.alejandra;
      };
    };
}
