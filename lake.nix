{ pkgs }: let
  importLakeManifest = manifestFile: let
      manifest = pkgs.lib.importJSON manifestFile;
    in
      pkgs.lib.warnIf (manifest.version != "1.1.0") ("Unknown version: " + manifest.version) manifest;
  depToPackage = dep : let
    src = builtins.fetchGit {
      inherit (dep) url rev;
    };
  in {
    inherit src;
    manifestFile = src / dep.manifestFile;
  };
  # Builds a Lean package by reading the manifest file.
  mkPackage = { src, manifestFile ? "${src}/lake-manifest.json", roots ? null } : let
    manifest = importLakeManifest manifestFile;
    deps = builtins.map (dep : mkPackage (depToPackage dep)) manifest.packages;
  in pkgs.lean.buildLeanPackage {
    inherit (manifest) name;
    roots = if builtins.isNull roots then [ manifest.name ] else roots;
    src = pkgs.lib.cleanSource src;
  };
in {
  inherit mkPackage;
}
