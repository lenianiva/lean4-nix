{
  pkgs-bin,
  lake2nix-bin,
  pkgs,
}: let
  inherit (pkgs-bin) lib;
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
  lake2nix = pkgs.callPackage lib/lake.nix {};
in
  {
    lean-bin = pkgs-bin.lean;
    leanc-bin = pkgs-bin.lean.leanc;
    lean = pkgs.lean;
    leanc = pkgs.lean.leanc;
    # Tests that the executable can run.
    lean-bin-run = pkgs-bin.testers.testVersion {package = pkgs-bin.lean;};
  }
  // (generate-lake-tests {
    lake = lake2nix-bin;
    lean = pkgs-bin.lean;
    prefix = "bin-";
  })
  // (generate-lake-tests {
    lake = lake2nix;
    lean = pkgs.lean;
  })
