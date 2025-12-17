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
  # An internal wrapper around `mkDerivation` which sets up the lake manifest and runs `lake build`. End users should call `buildDeps` and `mkPackage` instead
  mkLakeDerivation = args @ {
    # Name of the build target used to build shared and static facets. When building with `mkPackage` this is not used as the `buildPhase` is overriden
    name,
    # Path to the source
    src,
    # Attr set of the Lake package's dependency derivations
    deps ? {},
    ...
  }: let
    manifest = importLakeManifest "${src}/lake-manifest.json";
    # Creates a surrogate manifest with paths to the Nix store
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

        # Overrides the `lake-manifest.json` Git source with path dependencies which are written to `.lake/package-overrides.json` and automatically picked up by Lake
        configurePhase = ''
          runHook preConfigure
          mkdir -p .lake
          if [ ! -e .lake/package-overrides.json ]; then
            ln -s ${replaceManifest} .lake/package-overrides.json
          fi
          runHook postConfigure
        '';

        # Builds the default facets of the Lake package as well as the shared and static facets of the `name` library.
        # Building the `shared` and `static` facets generates the library's `.export` files for use as a dependency, which allows its Nix path to be read-only
        # Overriden by `mkPackage`, as top-level build targets may not be libraries
        buildPhase = ''
          runHook preBuild
          lake build
          lake build ${capitalize name}:shared
          lake build ${capitalize name}:static
          runHook postBuild
        '';

        # Copies the source and `.lake` artifacts to the out path for later reuse as dependencies. Overriden by `mkPackage` for configuration of top-level build targets
        installPhase = ''
          runHook preInstall
          mkdir -p $out/
          mv * $out/
          mv .lake $out/
          runHook postInstall
        '';
      }
      # Prevents implicit arguments from being coerced to input strings in `mkDerivation`
      // (builtins.removeAttrs args ["deps" "depOverride" "depOverrideDeriv" "lakeDeps" "lakeArtifacts"])
    );

  # Builds only the dependencies of a Lake package based on its `lake-manifest.json` file. Returns an attr set of package derivations
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

    # Fetches the Git source of each dependency in the manifest
    depSources = builtins.listToAttrs (builtins.map (info: {
        inherit (info) name;
        value = builtins.fetchGit {
          inherit (info) url rev;
          shallow = true;
        };
      })
      manifest.packages);

    # Constructs dependency name map
    flatDeps =
      lib.mapAttrs (
        _name: src: let
          manifest = importLakeManifest "${src}/lake-manifest.json";
          deps = builtins.map ({name, ...}: name) manifest.packages;
        in
          deps
      )
      depSources;

    # Builds all dependencies, overriding with any custom arguments from `depOverride` or pre-built derivations from `depOverrideDeriv`
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

  # Builds a given target of a Lake package with `lake build`, building dependencies first if necessary
  #
  # Optional/implicit arguments:
  # - `lakeDeps` takes an attr set of dependency derivations built by `buildDeps`. If not specified, `mkPackage` will call `buildDeps` anyway.
  # - `lakeArtifacts` takes a derivation from a previous `mkPackage` invocation and copies the `.lake` directory to the current build directory. Useful for incremental builds, e.g. reusing a package's library target artifacts when building an executable or test target.
  # - `depOverride` and `depOverrideDeriv` can also be passed through as args to `buildDeps`, but are overriden by `lakeDeps` if specified
  # Any input phases and hooks will be passed through to `mkDerivation`
  mkPackage = args @ {
    # Name of the build target, must be defined in `lakefile.lean`
    name,
    # Path to the source
    src,
    # Static library dependencies, passed as `nativeBuildInputs` to `mkDerivation`
    staticLibDeps ? [],
    # Whether to build `shared` and `static` facets of a library target
    buildLibrary ? false,
    # Whether to export `.lake` artifacts and source for incremental builds
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
        # Copies any given Lake artifacts to the build directory
        patchPhase = args.patchPhase or lib.concatStringsSep "\n" [
          "runHook prePatch"
          (
            if args ? lakeArtifacts
            then ''
              cp -R ${args.lakeArtifacts.outPath}/.lake .
              chmod -R +w .lake
            ''
            else ""
          )
          "runHook postPatch"
        ];

        # Builds the `name` target and its library facets if specified
        buildPhase = args.buildPhase or lib.concatStringsSep "\n" [
          ''
            runHook preBuild
            lake build ${name}
          ''
          (
            # Target must be a library or this will fail
            if buildLibrary
            then ''
              lake build ${name}:shared
              lake build ${name}:static
            ''
            else ""
          )
          "runHook postBuild"
        ];

        # Copies any executable to the out path, as well as the source and `.lake` artifacts if specified
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
