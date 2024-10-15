{
  description = "Lean 4 Nix Flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
    flake-utils.url = "github:numtide/flake-utils";
    lean = {
      url = "github:leanprover/lean4?ref=v4.12.0";
      flake = false;
    };
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    flake-utils,
    lean,
    ...
  } : let
    systems = [
      "x86_64-linux"
      "x86_64-darwin"
      "aarch64-linux"
      "aarch64-darwin"
    ];
  in {
    templates = {
      lib = {
        path = ./templates/lib;
        description = "Example Lean Project";
      };
      default = self.templates.lib;
    };
  } // flake-utils.lib.eachSystem systems (system: let
      pkgs = import nixpkgs { inherit system; };
      lean-packages = pkgs.callPackage ./packages.nix { src = lean; };
      checks = pkgs.callPackage ./checks.nix { inherit lean-packages; };
    in
    {
      packages = {
        inherit (lean-packages) lean-all lean buildLeanPackage;
        inherit (checks) example;
      };
    });
}
