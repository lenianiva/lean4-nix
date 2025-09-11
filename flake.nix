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
        # Pre-built binary
        lean-bin = self.fetchBinaryLean (import ./manifests/v4.22.0.nix) pkgs;
        lean = pkgs.callPackage ./lib/packages.nix {
          inherit lean-bin;
          inherit (import ./manifests/v4.22.0.nix) buildLeanPackage;
        };
      in {
        _module.args.pkgs = import nixpkgs {
          inherit system;
          overlays = [(self.readToolchainFile ./templates/minimal/lean-toolchain)];
        };

        packages = {
          inherit (pkgs) lean;
          inherit lean-bin;
          minimal-bin =
            (lean.buildLeanPackage {
              name = "Example";
              roots = ["Main"];
              src = pkgs.lib.cleanSource ./templates/minimal;
            })
            .executable;
        };
        devShells.default = pkgs.mkShell {
          buildInputs = [(pkgs.callPackage ./lib/toolchain.nix {}).toolchain-fetch];
        };

        checks = import ./checks.nix {inherit pkgs;};

        formatter = pkgs.alejandra;
      };
    };
}
