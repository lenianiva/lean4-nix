{
  pkgs,
  lib,
  stdenv,
  lean,
}: let
  capitalize = s: let
    first = lib.toUpper (builtins.substring 0 1 s);
    rest = builtins.substring 1 (-1) s;
  in
    first + rest;
  importLakeManifest = manifestFile: let
    manifest = lib.importJSON manifestFile;
  in
    lib.warnIf (manifest.version != "1.1.0") ("Unknown version: " + builtins.toString manifest.version) manifest;
  # A wrapper around `mkDerivation` which sets up the lake manifest
  mkLakeDerivation = args @ {
    src,
    deps ? {},
    ...
  }: let
    manifest = importLakeManifest "${src}/lake-manifest.json";
    # create a surrogate manifest
    replaceManifest =
      pkgs.writers.writeJSON "lake-manifest.json"
      (
        lib.setAttr manifest "packages" (builtins.map ({
            name,
            inherited ? false,
            ...
          }: {
            inherit name inherited;
            type = "path";
            dir = deps.${name};
          })
          manifest.packages)
      );
  in
    stdenv.mkDerivation (
      {
        buildInputs = [lean.lean-all];

        configurePhase = ''
          runHook preConfigure
          rm lake-manifest.json
          ln -s ${replaceManifest} lake-manifest.json
          runHook postConfigure
        '';

        buildPhase = ''
          runHook preBuild
          lake build
          runHook postBuild
        '';
        installPhase = ''
          runHook preInstall
          mkdir -p $out/
          mv * $out/
          mv .lake $out/
          runHook postInstall
        '';
      }
      // (builtins.removeAttrs args ["deps"])
    );
  # Builds a Lean package by reading the manifest file.
  mkPackage = args @ {
    # Name of the build target, must be defined in `lakefile.lean`
    name,
    # Path to the source
    src,
    # Path to the `lake-manifest.json` file
    manifestFile ? "${src}/lake-manifest.json",
    # Static library dependencies
    staticLibDeps ? [],
    # Override derivation args in dependencies
    depOverride ? {},
    ...
  }: let
    manifest = importLakeManifest manifestFile;

    depSources = builtins.listToAttrs (builtins.map (info: {
        inherit (info) name;
        value = builtins.fetchGit {
          inherit (info) url rev;
          shallow = true;
        };
      })
      manifest.packages);
    # construct dependency name map
    flatDeps =
      lib.mapAttrs (
        _name: src: let
          manifest = importLakeManifest "${src}/lake-manifest.json";
          deps = builtins.map ({name, ...}: name) manifest.packages;
        in
          deps
      )
      depSources;

    # Build all dependencies
    manifestDeps = builtins.listToAttrs (builtins.map (info: {
        inherit (info) name;
        value = mkLakeDerivation ({
            inherit (info) name url;
            src = depSources.${info.name};
            deps = builtins.listToAttrs (builtins.map (name: {
                inherit name;
                value = manifestDeps.${name};
              })
              flatDeps.${info.name});
          }
          // (depOverride.${info.name} or {}));
      })
      manifest.packages);
  in
    mkLakeDerivation ({
        inherit name src;
        deps = manifestDeps;
        nativeBuildInputs = staticLibDeps;
        buildPhase =
          args.buildPhase
          or ''
            runHook preBuild
            lake build ${name}
            runHook postBuild
          '';
        installPhase =
          args.installPhase
          or ''
            runHook preInstall
            mkdir $out
            if [ -d .lake/build/bin ]; then
              mv .lake/build/bin $out/
            fi
            if [ -d .lake/build/lib ]; then
              mv .lake/build/lib $out/
            fi
            runHook postInstall
          '';
      }
      // (depOverride.${manifest.name} or {}));
in {
  inherit mkLakeDerivation mkPackage;
}
