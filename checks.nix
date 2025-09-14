{
  pkgs,
  lake2nix,
  pkgs-built,
}: let
  inherit (pkgs) lib;
  generate-lake-tests = {
    prefix ? "",
    lean,
    lake,
  }: let
    minimal-direct = lean.buildLeanPackage {
      name = "Example";
      roots = ["Main"];
      src = lib.cleanSource ./templates/minimal;
    };
    minimal-manifest = lake.mkPackage {
      src = lib.cleanSource ./templates/minimal;
      roots = ["Main"];
    };
    dependency-manifest = lake.mkPackage {
      src = lib.cleanSource ./templates/dependency;
      roots = ["Example"];
    };
  in
    lib.mapAttrs' (name: value: lib.nameValuePair "${prefix}${name}" value)
    {
      minimal-direct-bin = minimal-direct.executable;
      minimal-manifest-bin = minimal-manifest.executable;
      dependency-manifest-bin = dependency-manifest.executable;
    };
  lake2nix-built = pkgs-built.callPackage lib/lake.nix {};
in
  {
    lean-bin = pkgs.lean;
    leanc-bin = pkgs.lean.leanc;
    lean = pkgs-built.lean;
    leanc = pkgs-built.lean.leanc;
  }
  // (generate-lake-tests {
    lake = lake2nix;
    lean = pkgs.lean;
    prefix = "bin-";
  })
  // (generate-lake-tests {
    lake = lake2nix-built;
    lean = pkgs-built.lean;
  })
