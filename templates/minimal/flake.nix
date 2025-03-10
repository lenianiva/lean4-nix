{
  description = "Lean 4 Example Project";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    lean4-nix = {
      url = "github:lenianiva/lean4-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    nixpkgs,
    lean4-nix,
    ...
  }: let
    perSystem = f:
      nixpkgs.lib.genAttrs [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ] (system:
        f (import nixpkgs {
          inherit system;
          overlays = [(lean4-nix.readToolchainFile ./lean-toolchain)];
        }));
  in {
    packages = perSystem (pkgs: {
      default =
        pkgs.callPackage ./default.nix {};
    });

    devShells = perSystem (pkgs: {
      default = pkgs.mkShell {
        packages = with pkgs.lean; [lean lean-all];
      };
    });
  };
}
