{ pkgs }: let
  capitalize = s:
    let
      first = pkgs.lib.toUpper (builtins.substring 0 1 s);
      rest = builtins.substring 1 (-1) s;
    in
      first + rest;
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
    manifestFile = "${src}/${dep.manifestFile}";
  };
  # Builds a Lean package by reading the manifest file.
  mkPackage = { src, manifestFile ? "${src}/lake-manifest.json", roots ? null } : let
    manifest = importLakeManifest manifestFile;
    # Build all dependencies using `buildLeanPackage`
    deps = builtins.map (dep : mkPackage (depToPackage dep)) manifest.packages;
  in pkgs.lean.buildLeanPackage {
    inherit (manifest) name;
    roots = if builtins.isNull roots then [ (capitalize manifest.name) ] else roots;
    src = pkgs.lib.cleanSource src;
    deps = deps ++ [ pkgs.lean.Init pkgs.lean.Lean ];
  };
in {
  inherit mkPackage;
}
