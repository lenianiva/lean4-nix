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
    name,
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
          mkdir -p .lake
          if [ ! -e .lake/package-overrides.json ]; then
            ln -s ${replaceManifest} .lake/package-overrides.json
          fi
          runHook postConfigure
        '';

        buildPhase = ''
          runHook preBuild
          lake build
          lake build ${capitalize name}:shared
          lake build ${capitalize name}:static
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
      // (builtins.removeAttrs args ["deps" "depOverride" "depOverrideDeriv" "lakeDeps" "lakeArtifacts"])
    );

  buildDeps = {
    # Path to the source
    src,
    # Path to the `lake-manifest.json` file
    manifestFile ? "${src}/lake-manifest.json",
    # Override derivation args in dependencies
    depOverride ? {},
    # Override derivation entirely in dependencies
    depOverrideDeriv ? {},
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
        value =
          depOverrideDeriv.${
            info.name
          } or (mkLakeDerivation ({
              inherit (info) name url;
              src = depSources.${info.name};
              deps = builtins.listToAttrs (builtins.map (name: {
                  inherit name;
                  value = manifestDeps.${name};
                })
                flatDeps.${info.name});
            }
            // (depOverride.${info.name} or {})));
      })
      manifest.packages);
  in
    manifestDeps;

  # Builds a Lean package by reading the manifest file.
  # Other possible arguments are `lakeDeps` and `lakeArtifacts`
  # `depOverride` and `depOverrideDeriv` can also be passed through to `buildDeps`, but are overriden by `lakeDeps`
  # Also, any input phase hooks will get passed through to `mkDerivation`
  mkPackage = args @ {
    # Name of the build target, must be defined in `lakefile.lean`
    name,
    # Path to the source
    src,
    # Static library dependencies
    staticLibDeps ? [],
    # Build `shared` and `static` facets of a library target
    buildLibrary ? false,
    # Export `.lake` artifacts for reuse
    installArtifacts ? true,
    ...
  }: let
    deps = args.lakeDeps or (buildDeps (builtins.removeAttrs args ["name"]));
  in
    mkLakeDerivation (args
      // {
        inherit name src deps;
        nativeBuildInputs = staticLibDeps;

        # TODO: Use zstd tarball instead of cp
        # https://github.com/ipetkov/crane/blob/master/lib/setupHooks/inheritCargoArtifactsHook.sh#L28
        patchPhase =
          args.patchPhase or (
            if args ? lakeArtifacts
            then ''
              cp -R ${args.lakeArtifacts.outPath}/.lake .
              chmod -R +w .lake
            ''
            else ""
          );

        buildPhase = args.buildPhase or lib.concatStringsSep "\n" [
          ''
            runHook preBuild
            lake build ${name}
          ''
          (
            if buildLibrary
            then ''
              lake build ${name}:shared
              lake build ${name}:static
            ''
            else ""
          )
          "runHook postBuild"
        ];

        installPhase = args.installPhase
          or lib.concatStringsSep "\n" [
          ''
            runHook preInstall
            mkdir -p $out
            if [ -d .lake/build/bin ]; then
              cp -R .lake/build/bin $out
            fi
          ''
          (
            # TODO: Compress into zstd tarball instead of mv
            # https://github.com/ipetkov/crane/blob/master/lib/setupHooks/installCargoArtifactsHook.sh#L39
            if installArtifacts
            then ''
              mv * $out
              mv .lake $out
            ''
            else ""
          )
          "runHook postInstall"
        ];
      });
in {
  inherit mkLakeDerivation buildDeps mkPackage;
}
