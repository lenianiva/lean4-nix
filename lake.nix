{pkgs}: let
  capitalize = s: let
    first = pkgs.lib.toUpper (builtins.substring 0 1 s);
    rest = builtins.substring 1 (-1) s;
  in
    first + rest;
  importLakeManifest = manifestFile: let
    manifest = pkgs.lib.importJSON manifestFile;
  in
    pkgs.lib.warnIf (manifest.version != "1.1.0") ("Unknown version: " + builtins.toString manifest.version) manifest;
  depToPackage = dep: let
    src = pkgs.lib.cleanSource (builtins.fetchGit {
      inherit (dep) url rev;
      shallow = true;
    });
  in {
    inherit src;
    manifestFile = "${src}/${dep.manifestFile}";
  };
  # Builds a Lean package by reading the manifest file.
  mkPackage = {
    # Path to the source
    src,
    # Path to the `lake-manifest.json` file
    manifestFile ? "${src}/lake-manifest.json",
    # Root module
    roots ? null,
    # Default dependencies
    deps ? with pkgs.lean; [Init Std Lean],
    # Static library dependencies
    staticLibDeps ? null,
  }: let
    manifest = importLakeManifest manifestFile;
    # Build all dependencies using `buildLeanPackage`
    manifestDeps = builtins.map (dep: mkPackage (depToPackage dep)) manifest.packages;
  in
    pkgs.lean.buildLeanPackage {
      inherit (manifest) name;
      inherit src;
      roots =
        if builtins.isNull roots
        then [(capitalize manifest.name)]
        else roots;
      deps = deps ++ manifestDeps;
      staticLibDeps =
        if builtins.isNull staticLibDeps
        then []
        else staticLibDeps;
      # Fixes some symbol not found errors
      groupStaticLibs = true;
    };
in {
  inherit mkPackage;
}
