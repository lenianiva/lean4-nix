{
  description = "Lean 4 Example Project";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
    flake-parts.url = "github:hercules-ci/flake-parts";
    systems.url = "github:nix-systems/default";
    lean4-nix.url = "github:lenianiva/lean4-nix";
  };

  outputs = inputs @ { nixpkgs, flake-parts, systems, lean4-nix, ... }: flake-parts.lib.mkFlake { inherit inputs; } {
    systems = import systems;

    perSystem = { pkgs, system, ... }: {
      _module.args.pkgs = import nixpkgs {
        inherit system;
        overlays = [ (lean4-nix.readToolchainFile ./lean-toolchain) ];
      };

      devShells.default = pkgs.mkShell {
        packages = with pkgs.lean; [ lean lean-all ];
      };

      formatter = pkgs.nixpkgs-fmt;

      packages.default = (pkgs.lean.buildLeanPackage {
        name = "Example";
        roots = [ "Main" ];
        src = pkgs.lib.cleanSource ./.;
      }).executable;
    };
  };
}
