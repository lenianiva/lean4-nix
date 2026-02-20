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
      name = "minimal";
      src = lib.cleanSource ./templates/minimal;
    };
    dependency-manifest = lake.mkPackage {
      name = "Example";
      src = lib.cleanSource ./templates/dependency;
      buildLibrary = true;
    };
    incremental-deps = lake2nix.buildDeps {
      src = lib.cleanSource ./templates/incremental;
      # Override with up to date `dependency` dep
      depOverrideDeriv = {
        Example = dependency-manifest;
      };
    };
    incremental-args = {
      lakeDeps = incremental-deps;
      src = lib.cleanSource ./templates/incremental;
    };
    incremental-lib = lake2nix.mkPackage (incremental-args
      // {
        name = "Incremental";
        buildLibrary = true;
      });
    incremental-test = lake2nix.mkPackage (incremental-args
      // {
        name = "IncrementalTest";
        lakeArtifacts = incremental-lib;
        installArtifacts = false;
      });
  in
    lib.mapAttrs' (name: value: lib.nameValuePair "${prefix}${name}" value)
    rec {
      minimal-direct-lib = minimal-direct.sharedLib;
      minimal-direct-bin = minimal-direct.executable;
      minimal-manifest-bin = minimal-manifest;
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
      inherit dependency-manifest incremental-lib incremental-test;
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
