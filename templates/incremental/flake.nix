{
  description = "Lean 4 Example Project";

  inputs = {
    nixpkgs.follows = "lean4-nix/nixpkgs";
    flake-parts.url = "github:hercules-ci/flake-parts";
    lean4-nix.url = "github:lenianiva/lean4-nix";
  };

  outputs = inputs @ {
    nixpkgs,
    flake-parts,
    lean4-nix,
    ...
  }:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-darwin"
        "x86_64-linux"
      ];

      perSystem = {
        system,
        pkgs,
        ...
      }: let
        lake2nix = pkgs.callPackage lean4-nix.lake {};
        # Build all dependencies from `lake-manifest.json`
        lakeDeps = lake2nix.buildDeps {
          src = ./.;
        };
        # Arguments shared by all build targets
        commonArgs = {
          inherit lakeDeps;
          src = ./.;
        };
        exampleLib = lake2nix.mkPackage (commonArgs
          // {
            name = "Example";
            # Build library facets ahead of time for use as a dependency
            buildLibrary = true;
          });
        exampleTest = lake2nix.mkPackage (commonArgs
          // {
            name = "ExampleTest";
            # Copy `.lake` artifacts from library derivation
            lakeArtifacts = exampleLib;
            # Don't export source code or `.lake` artifacts, since a test won't be used as a dependency
            installArtifacts = false;
          });
      in {
        _module.args.pkgs = import nixpkgs {
          inherit system;
          overlays = [(lean4-nix.readToolchainFile ./lean-toolchain)];
        };

        packages = {
          default = exampleLib;
          test = exampleTest;
        };

        devShells.default = pkgs.mkShell {
          packages = with pkgs.lean; [lean-all];
        };
      };
    };
}
