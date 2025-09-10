let
  manifests = import ../manifests;
  fetchBinaryLean = manifest: pkgs: let
    version = builtins.substring 1 (-1) manifest.tag;
    tarball = fetchTarball {
      url = "https://github.com/leanprover/lean4/releases/download/${manifest.tag}/lean-${version}-linux.tar.zst";
      sha256 = manifest.toolchain.linux.sha256;
    };
  in {
    lean = pkgs.stdenv.mkDerivation {
      name = "lean";
      src = tarball;
      dontBuild = true;
      dontConfigure = true;
      installPhase = ''
        mkdir -p $out/
        cp -r ./bin $out/
        cp -r ./lib $out/
      '';
    };
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
