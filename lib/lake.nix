{
  pkgs,
  lib,
  stdenv,
  lean,
  git,
  symlinkJoin,
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
  mkPackageWithDeps = {
    name,
    src,
    deps ? {},
    url,
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
    stdenv.mkDerivation {
      inherit src name;
      buildInputs = [lean];

      buildPhase = ''
        mkdir .lake
        rm lake-manifest.json
        ln -s ${replaceManifest} lake-manifest.json
        lake build
      '';
      installPhase = ''
        mkdir -p $out/
        mv * $out/
        mv .lake $out/
      '';
    };
  # Builds a Lean package by reading the manifest file.
  mkPackage = args @ {
    # Path to the source
    src,
    # Path to the `lake-manifest.json` file
    manifestFile ? "${src}/lake-manifest.json",
    # Root module
    roots ? null,
    # Static library dependencies
    staticLibDeps ? [],
  }: let
    manifest = importLakeManifest manifestFile;

    roots =
      args.roots or [(capitalize manifest.name)];

    depSources = builtins.listToAttrs (builtins.map (info: {
        inherit (info) name;
        value = builtins.fetchGit {
          inherit (info) url rev;
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
        value = mkPackageWithDeps {
          inherit (info) name url;
          src = depSources.${info.name};
          deps = builtins.listToAttrs (builtins.map (name: {
              inherit name;
              value = manifestDeps.${name};
            })
            flatDeps.${info.name});
        };
      })
      manifest.packages);
    replaceManifest =
      pkgs.writers.writeJSON "lake-manifest.json"
      (
        lib.setAttr manifest "packages" (builtins.map ({
            name,
            inherited,
            ...
          }: {
            inherit inherited name;
            type = "path";
            dir = manifestDeps.${name};
          })
          manifest.packages)
      );
  in
    stdenv.mkDerivation {
      inherit src;
      inherit (manifest) name;
      buildInputs = [lean];
      nativeBuildInputs = staticLibDeps;
      buildPhase = ''
        mkdir .lake
        rm lake-manifest.json
        ln -s ${replaceManifest} lake-manifest.json
        lake build #${builtins.concatStringsSep " " roots}
      '';
      installPhase = ''
        mkdir $out
        if [ -d .lake/build/bin ]; then
          mv .lake/build/bin $out/
        fi
        if [ -d .lake/build/lib ]; then
          mv .lake/build/lib $out/
        fi
      '';
    };
in {
  inherit mkPackage;
}
