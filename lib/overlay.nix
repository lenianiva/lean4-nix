let
  manifests = import ../manifests;
  fetchBinaryLean = manifest: {
    stdenv,
    system,
    lib,
    fixDarwinDylibNames,
    autoPatchelfHook,
    ...
  }: let
    version = builtins.substring 1 (-1) manifest.tag;
    system-tag = builtins.getAttr system {
      x86_64-linux = "linux";
      aarch64-linux = "linux_aarch64";
      x86_64-darwin = "darwin";
      aarch64-darwin = "darwin_aarch64";
    };
    tarball = fetchTarball {
      url = "https://github.com/leanprover/lean4/releases/download/${manifest.tag}/lean-${version}-${system-tag}.tar.zst";
      sha256 = manifest.toolchain.${system}.sha256;
    };
    mkDerivation = args:
      stdenv.mkDerivation (args
        // {
          dontBuild = true;
          dontConfigure = true;
          nativeBuildInputs =
            []
            ++ lib.optional stdenv.isDarwin fixDarwinDylibNames
            ++ lib.optionals stdenv.isLinux [autoPatchelfHook stdenv.cc.cc.lib];
        });
    lean-all = mkDerivation {
      name = "lean";
      src = tarball;
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
    lean-all
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
  readSrc = {
    src,
    bootstrap,
    buildLeanPackage ? null,
  }: final: prev:
    prev
    // rec {
      lean =
        (prev.callPackage ./packages.nix {inherit src bootstrap buildLeanPackage;})
        // {
          lake = lean.Lake-Main.executable;
        };
    };
  readFromGit = {
    args,
    bootstrap,
    buildLeanPackage ? null,
  }:
    readSrc {
      src = builtins.fetchGit args;
      inherit bootstrap buildLeanPackage;
    };
  readRev = {
    rev,
    bootstrap,
    buildLeanPackage ? null,
    tag,
    toolchain,
  }:
    readFromGit {
      args = {
        url = "https://github.com/leanprover/lean4.git";
        shallow = true;
        ref = "refs/tags/${tag}";
        inherit rev;
      };
      inherit bootstrap buildLeanPackage;
    };
  tags = builtins.mapAttrs (tag: manifest: readRev manifest) manifests;
  readToolchain = toolchain:
    builtins.addErrorContext "Only leanprover/lean4:{tag} toolchains are supported" (let
      matches = builtins.match "^[[:space:]]*leanprover/lean4:([a-zA-Z0-9\\-\\.]+)[[:space:]]*$" toolchain;
      tag = builtins.head matches;
    in
      builtins.getAttr tag tags);
  readToolchainFile = toolchainFile: readToolchain (builtins.readFile toolchainFile);
in {
  inherit fetchBinaryLean readSrc readFromGit readRev tags readToolchain readToolchainFile;
}
