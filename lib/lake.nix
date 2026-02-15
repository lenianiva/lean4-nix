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
    # Whether to build `shared` and `static` facets of a library target, and elaborate lakefile.lean into `.lake/config/<pkgName>` if applicable.
    buildLibrary ? false,
    # Whether to export `.lake` artifacts and source for incremental builds
    installArtifacts ? true,
    ...
  }: let
    manifest = importLakeManifest "${src}/lake-manifest.json";
    # Creates a surrogate manifest with paths to the Nix store
    replaceManifest = (
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
    replaceManifestJson = pkgs.writers.writeJSON "lake-manifest.json" replaceManifest;
    # Creates a manifest for a downstream project that imports the library, which will be built alongside it in the build phase. This is needed because in Lean 4.26.0+ Lake re-elaborates the lakefile as `.lake/config/<pkgName>` when a library is imported, and any writes to `.lake` must happen before the build completes and the dependency path is imported as a read-only Nix store path.
    replaceManifestImportJson =
      pkgs.writers.writeJSON "lake-manifest.json"
      (
        replaceManifest
        // {
          packages =
            replaceManifest.packages
            ++ [
              {
                type = "path";
                scope = "";
                name = name;
                manifestFile = "lake-manifest.json";
                inherited = false;
                dir = "..";
                configFile = "lakefile.lean";
              }
            ];
          name = "${name}Import";
        }
      );
    # Creates the import project's lakefile. Note we can't use `lake new` because it uses Git
    lakefile-import = pkgs.writeText "lakefile.toml" ''
      name = "${name}Import"
      version = "0.1.0"
      defaultTargets = ["${name}-import"]

      [[require]]
      name = "${name}"
      path = ".."

      [[lean_exe]]
      name = "${name}-import"
      root = "Main"
    '';
    # Creates the import project's `Main.lean`
    main-import = pkgs.writeText "Main.lean" ''
      import ${name}
      def main : IO Unit := IO.println s!"Hello, world!"
    '';
  in
    stdenv.mkDerivation (
      {
        buildInputs = [pkgs.rsync lean.lean-all];

        # If building a library with a `lakefile.lean`, create a wrapper project that imports the library.
        patchPhase = ''
          runHook prePatch
          ${lib.optionalString buildLibrary ''
            if [ -e "lakefile.lean" ]; then
              mkdir ${name}-import
              ln -s ${main-import} ${name}-import/Main.lean
              ln -s ${lakefile-import} ${name}-import/lakefile.toml
              ln -s ${replaceManifestImportJson} ${name}-import/lake-manifest.json
              cp lean-toolchain ${name}-import
            fi
          ''}
          runHook postPatch
        '';

        # Overrides the `lake-manifest.json` Git source with path dependencies which are written to `.lake/package-overrides.json` and automatically picked up by Lake
        configurePhase = ''
          runHook preConfigure
          mkdir -p .lake
          if [ ! -e .lake/package-overrides.json ]; then
            ln -s ${replaceManifestJson} .lake/package-overrides.json
          fi
          runHook postConfigure
        '';

        # Builds the default facets of the Lake package as well as the shared and static facets of the `name` library. Building the `shared` and `static` facets generates the library's `.export` files for use as a dependency, which allows its Nix path to be read-only
        # Also builds the library's import project from `patchPhase` if applicable
        # NOTE: We assume most projects have the same name for the package and default library, where the latter is capitalized (e.g. `aesop` and `Aesop`, `batteries` and `Batteries`). If this is not the case, the user can provide their own `buildPhase` either in a `depOverride` for `buildDeps` or directly as an argument to in `mkPackage`. If there are multiple libraries used from the package, the user can provide a `preBuild` or `postBuild` hook to build the requisite `shared`/`staic` facets
        buildPhase = ''
          runHook preBuild
          lake build ${name}
          ${lib.optionalString buildLibrary ''
            lake build ${capitalize name}:shared
            lake build ${capitalize name}:static
            if [ -e lakefile.lean ]; then
              cd ${name}-import
              lake build
              cd ..
            fi
          ''}
          runHook postBuild
        '';

        # Copies the source and `.lake` artifacts to the out path for later reuse as dependencies, respecting `.gitignore`
        # TODO: Compress into zstd tarball instead of rsync/cp
        # https://github.com/ipetkov/crane/blob/master/lib/setupHooks/installCargoArtifactsHook.sh#L39
        installPhase = ''
          runHook preInstall
          mkdir -p $out/
          ${lib.optionalString installArtifacts ''
            rsync -a --exclude="${name}-import" --filter=":- .gitignore" ./ "$out/"
            cp -r .lake $out
          ''}
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
              buildLibrary = true;
            }
            // (depOverride.${info.name} or {})));
      })
      manifest.packages);
  in
    manifestDeps;

  # Builds a given target of a Lake package with `lake build`, building any dependencies first and importing them via their Nix store paths
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
        prePatch =
          args.prePatch or
            (
            if args ? lakeArtifacts
            then ''
              cp -R ${args.lakeArtifacts.outPath}/.lake .
              chmod -R +w .lake
            ''
            else ""
          );

        # Copies any executable to the out path, as well as the source and `.lake` artifacts if specified
        postInstall =
          args.postInstall or ''
            if [ -d .lake/build/bin ]; then
              cp -R .lake/build/bin $out
            fi
          '';
      });
in {
  inherit mkLakeDerivation buildDeps mkPackage;
}
