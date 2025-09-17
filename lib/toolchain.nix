{
  config,
  lib,
  pkgs,
  fetchurl,
  stdenv,
  system,
  zstd,
  callPackage,
  fixDarwinDylibNames,
  writeShellApplication,
  autoPatchelfHook,
  ...
}: rec {
  toolchain-fetch = writeShellApplication {
    name = "toolchain-fetch";
    runtimeInputs = with pkgs; [jq git wget coreutils nix];
    text = ''exec ${./toolchain-fetch.sh} "$@"'';
  };
  srcFromManifest = manifest @ {
    tag,
    rev,
    ...
  }:
    builtins.fetchGit {
      url = "https://github.com/leanprover/lean4.git";
      shallow = true;
      ref = "refs/tags/${tag}";
      inherit rev;
    };
  fetchBinaryLean = manifest: let
    version = builtins.substring 1 (-1) manifest.tag;
    system-tag = builtins.getAttr system {
      x86_64-linux = "linux";
      aarch64-linux = "linux_aarch64";
      x86_64-darwin = "darwin";
      aarch64-darwin = "darwin_aarch64";
    };
    tarball = fetchurl {
      url = "https://github.com/leanprover/lean4/releases/download/${manifest.tag}/lean-${version}-${system-tag}.tar.zst";
      hash = manifest.toolchain.${system}.hash;
    };
    mkDerivation = args @ {nativeBuildInputs ? [], ...}:
      stdenv.mkDerivation (args
        // {
          nativeBuildInputs =
            nativeBuildInputs
            ++ lib.optional stdenv.isDarwin fixDarwinDylibNames
            ++ lib.optionals stdenv.isLinux [autoPatchelfHook stdenv.cc.cc.lib];
        });
    # A derivation whose only purpose is to make symlinks
    mkBareDerivation = args: stdenv.mkDerivation (args // {phases = ["installPhase"];});
    lean-all = mkDerivation {
      inherit version;
      name = "lean";
      src = tarball;
      nativeBuildInputs = [zstd];
      installPhase = ''
        mkdir -p $out/
        mv ./* $out/
      '';
    };
    LEAN_PATH = "${lean-all}/lib/lean";
    # Common function for reconstructing the standard libraries `Init`, `Std`,
    # `Lean` from binaries.
    mkLib = name: let
      # dangeorus operation, but should be fine since we discard the store paths
      prefix = builtins.unsafeDiscardStringContext "${lean-all}/lib/lean/";
      suffix = ".olean";
      # Collect all the modules (e.g. `Init.WF` from `Init`).
      #
      # View the list of modules by evaluating `lean-bin.{Init,Std,Lean}.mods`.
      moduleList =
        builtins.map (path: {
          name = builtins.replaceStrings ["/"] ["."] (lib.removePrefix prefix (lib.removeSuffix suffix (builtins.unsafeDiscardStringContext path)));
          value = lib.removePrefix prefix (lib.removeSuffix suffix path);
        })
        (builtins.filter (lib.hasSuffix suffix)
          (lib.filesystem.listFilesRecursive "${lean-all}/lib/lean/${name}"));
      modules = builtins.mapAttrs (modname: path:
        mkBareDerivation {
          name = "${modname}";
          src = lean-all;
          inherit LEAN_PATH;
          propagatedLoadDynlibs = [];
          installPhase = ''
            mkdir -p $out
            ln -s ${lean-all}/lib/lean/${path}.* $out/
          '';
        }) (builtins.listToAttrs moduleList);
    in {
      allExternalDeps = [];
      staticLibDeps = [];
      mods =
        modules
        // {
          "${name}" = mkBareDerivation {
            name = "${name}-mods";
            src = lean-all;
            inherit LEAN_PATH;
            propagatedLoadDynlibs = [];
            installPhase = ''
              mkdir -p $out
              ln -s ${lean-all}/lib/lean/${name}/* $out/
            '';
          };
        };
      sharedLib = "${lean-all}/lib/lean";
      staticLib = mkBareDerivation {
        inherit name;
        src = lean-all;
        installPhase = ''
          mkdir -p $out
          ln -s ${lean-all}/lib/lean/lib${name}.a $out/lib${name}.a
        '';
      };
    };
  in
    callPackage ./packages.nix {
      lean-bin =
        lean-all
        // {
          lean = lean-all;
          leanc = lean-all;
          lake = lean-all;
          leanshared = mkBareDerivation {
            name = "leanshared";
            src = lean-all;
            installPhase = ''
              mkdir -p $out
              ln -s ${lean-all}/lib/lean/libleanshared.so $out/libleanshared.so
            '';
          };
          inherit LEAN_PATH;
          Init = mkLib "Init";
          Std = mkLib "Std";
          Lean = mkLib "Lean";
        };
      src = srcFromManifest manifest;
      inherit (manifest) bootstrap;
      buildLeanPackage = manifest.buildLeanPackage or null;
    };
}
