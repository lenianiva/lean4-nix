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
    rec {
      minimal-direct-lib = minimal-direct.sharedLib;
      minimal-direct-bin = minimal-direct.executable;
      minimal-manifest-bin = minimal-manifest.executable;
      minimal-exec = pkgs.testers.testEqualContents {
        assertion = "Call minimal";
        expected = pkgs.writeTextFile {
          name = "expected";
          text = "Da";
        };
        actual =
          pkgs.runCommand "actual"
          {}
          ''
            ${minimal-direct-bin}/bin/example | head -c 2 > $out
          '';
      };
      # Ensure the built executables can actually run on a VM
      minimal-exec-vm = pkgs.testers.runNixOSTest ({pkgs, ...}: {
        name = "Execute Lean Package";

        nodes = {
          server = {
            config,
            pkgs,
            ...
          }: {
            networking = {hostName = "hakkero";};
            environment = {
              variables.EDITOR = "vim";
              systemPackages = [
                pkgs.lean
                minimal-direct-bin
              ];
            };
          };
        };

        testScript = ''
          hakkero.start()
          hakkero.succeed("example")
        '';
      });
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
    prefix = "src-";
  })
