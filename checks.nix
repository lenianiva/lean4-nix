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
    dependency-deps = lake.buildDeps {
      src = lib.cleanSource ./templates/dependency;
    };
    dependency-manifest = lake.mkPackage {
      name = "Example";
      src = lib.cleanSource ./templates/dependency;
      lakeDeps = dependency-deps;
      buildLibrary = true;
    };
    incremental-deps = lake.buildDeps {
      src = lib.cleanSource ./templates/incremental;
    };
    incremental-args = {
      lakeDeps = incremental-deps;
      src = lib.cleanSource ./templates/incremental;
    };
    incremental-lib = lake.mkPackage (incremental-args
      // {
        name = "Incremental";
        buildLibrary = true;
      });
    incremental-test = lake.mkPackage (incremental-args
      // {
        name = "IncrementalTest";
        lakeArtifacts = incremental-lib;
        installArtifacts = false;
      });
    # Import `dependency` into `incremental` to test the `.lake` behavior for `lakefile.lean` dependencies
    incremental-test-dep = let
      all-deps = dependency-deps // {Example = dependency-manifest;};
      # Override package-overrides.json to include all deps (incremental + dependency)
      overridesJson = pkgs.writers.writeJSON "package-overrides.json" {
        version = "1.1.0";
        packagesDir = ".lake/packages";
        packages = map (name: {
          inherit name;
          inherited = false;
          type = "path";
          dir = ".lake/packages/${name}";
        }) (builtins.attrNames all-deps);
        name = "Incremental";
        lakeDir = ".lake";
      };
    in
      lake.mkPackage {
        name = "IncrementalTest";
        src = lib.cleanSource ./templates/incremental;
        lakeDeps = all-deps;
        prePatch = ''
          substituteInPlace lakefile.lean --replace-fail "package Incremental" 'require Example from "${dependency-manifest}"

          package Incremental'
          substituteInPlace Incremental.lean --replace-fail "import Batteries" 'import Batteries
          import Example'
          substituteInPlace IncrementalTest.lean --replace-fail "IO.println greeting" "IO.println cirno"
        '';
        preConfigure = ''
          mkdir -p .lake
          ln -s ${overridesJson} .lake/package-overrides.json
        '';
        installArtifacts = false;
      };
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
      inherit dependency-manifest incremental-lib incremental-test incremental-test-dep;
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
