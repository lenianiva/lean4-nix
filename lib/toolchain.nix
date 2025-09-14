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
  autoPatchelfHook,
  ...
}: rec {
  toolchain-fetch = pkgs.writeShellApplication {
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
      sha256 = manifest.toolchain.${system}.sha256;
    };
    # just copying files around
    mkDerivation = args @ {nativeBuildInputs, ...}:
      stdenv.mkDerivation (args
        // {
          phases = ["unpackPhase" "installPhase"];
          nativeBuildInputs =
            nativeBuildInputs
            ++ lib.optional stdenv.isDarwin fixDarwinDylibNames
            ++ lib.optionals stdenv.isLinux [autoPatchelfHook stdenv.cc.cc.lib];
        });
    lean-all = mkDerivation {
      name = "lean-bin";
      src = tarball;
      nativeBuildInputs = [zstd];
      installPhase = ''
        mkdir -p $out/
        cp -r ./bin $out/
        cp -r ./include $out/
        cp -r ./lib $out/
      '';
    };
    LEAN_PATH = "${lean-all}/lib/lean";
    mkLib = name: {
      allExternalDeps = [];
      staticLibDeps = [];
      mods = {
        "${name}" = mkDerivation {
          name = "${name}-mods";
          src = lean-all;
          inherit LEAN_PATH;
          propagatedLoadDynlibs = [];
          installPhase = ''
            mkdir -p $out
            cp -r "${lean-all}/lib/lean/${name}" $out/
          '';
        };
      };
      sharedLib = "${lean-all}/lib/lean";
      staticLib = mkDerivation {
        inherit name;
        src = lean-all;
        installPhase = ''
          mkdir -p $out
          ln -s ${lean-all}/lib/lean/lib${name}.a $out/lib${name}.a
        '';
      };
    };
  in
    (callPackage ./packages.nix {
      lean-bin = lean-all;
      src = srcFromManifest manifest;
      inherit (manifest) bootstrap;
      buildLeanPackage = manifest.buildLeanPackage or null;
    })
    // {
      lean = lean-all;
      leanc = lean-all;
      lake = lean-all;
      leanshared = mkDerivation {
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
}
