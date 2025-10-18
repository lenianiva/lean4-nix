{
  config,
  lib,
  pkgs,
  fetchurl,
  stdenv,
  system,
  zstd,
  clang,
  lld,
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
    lean-all = mkDerivation {
      inherit version;
      name = "lean";
      src = tarball;
      nativeBuildInputs = [zstd];
      installPhase = ''
        mkdir -p $out/
        rm bin/{clang,ld.lld,llvm-ar}
        ln -s ${clang}/bin/clang bin/
        ln -s ${lld}/bin/ld.lld bin/

        # Replace includes
        rm -r include/clang
        ln -s ${clang}/resource-root/include include/clang

        # Remove
        rm -r lib/clang

        mv ./* $out/
      '';
    };
    LEAN_PATH = "${lean-all}/lib/lean";
    # A derivation whose only purpose is to make symlinks
    mkBareDerivation = args: stdenv.mkDerivation (args // {phases = ["installPhase"];});
    commonSharedLib = mkBareDerivation {
      name = "libleanshared";
      src = lean-all;
      installPhase = ''
        mkdir -p $out
        ln -s ${lean-all}/lib/lean/libleanshared.* $out/
      '';
    };
    # Common function for reconstructing the standard libraries `Init`, `Std`,
    # `Lean` from binaries.
    mkLib = {
      name,
      allExternalDeps ? [],
    }: let
      # dangeorus operation, but should be fine since we discard the store paths
      prefix = builtins.unsafeDiscardStringContext "${lean-all}/lib/lean/";
      suffix = ".olean";
      centreOf = path: lib.removePrefix prefix (lib.removeSuffix suffix path);
      # Collect all the modules (e.g. `Init.WF` from `Init`).
      #
      # View the list of modules by evaluating `lean-bin.{Init,Std,Lean}.mods`.
      moduleList =
        builtins.map (path: {
          name = builtins.replaceStrings ["/"] ["."] (centreOf (builtins.unsafeDiscardStringContext path));
          value = centreOf path;
        })
        (builtins.filter (lib.hasSuffix suffix)
          (lib.filesystem.listFilesRecursive "${lean-all}/lib/lean/${name}"));
      modules = builtins.mapAttrs (modname: path:
        mkBareDerivation {
          name = "${modname}";
          src = lean-all;
          LEAN_PATH = "";
          propagatedLoadDynlibs = [];
          sharedLib = commonSharedLib;
          installPhase = ''
            mkdir -p $out/${dirOf path}
            base=${lean-all}/lib/lean/${path}
            ln -s $base.{ilean,olean} $out/${dirOf path}/
          '';
        }) (builtins.listToAttrs moduleList);
    in {
      inherit allExternalDeps;
      staticLibDeps = [];
      mods =
        modules
        // {
          # This builds the `Init`, `Std`, `Lean`, `Lake` libraries
          "${name}" = mkBareDerivation {
            inherit name LEAN_PATH;
            src = lean-all;
            propagatedLoadDynlibs = [];
            sharedLib = commonSharedLib;
            installPhase = ''
              mkdir -p $out
              ln -s ${lean-all}/lib/lean/${name}.{ilean,olean} $out/
            '';
          };
        };
      sharedLib = commonSharedLib;
      staticLib = mkBareDerivation {
        name = "${name}-lib";
        src = lean-all;
        installPhase = ''
          mkdir -p $out
          ln -s ${lean-all}/lib/lean/lib${name}.a $out/
        '';
      };
    };
  in
    callPackage ./packages.nix {
      lean-bin =
        lean-all
        // rec {
          lean = lean-all;
          leanc = lean-all;
          lake = lean-all;
          leanshared = mkBareDerivation {
            name = "leanshared";
            src = lean-all;
            installPhase = ''
              mkdir -p $out
              ln -s ${lean-all}/lib/lean/libleanshared.* $out/
            '';
          };
          inherit LEAN_PATH;
          Init = mkLib {name = "Init";};
          Std = mkLib {
            name = "Std";
            allExternalDeps = [Init];
          };
          Lean = mkLib {
            name = "Lean";
            allExternalDeps = [Std];
          };
          Lake = mkLib {
            name = "Lake";
            allExternalDeps = [Init Lean];
          };
          stdlib = [Init Std Lean Lake];
        };
      src = srcFromManifest manifest;
      inherit (manifest) bootstrap;
      buildLeanPackage = manifest.buildLeanPackage or null;
    };
}
