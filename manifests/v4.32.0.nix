{
  tag = "v4.32.0";
  rev = "8c9756b28d64dab099da31a4c09229a9e6a2ef35";
  toolchain = {
    aarch64-linux = {
      url = "https://github.com/leanprover/lean4/releases/download/v4.32.0/lean-4.32.0-linux_aarch64.tar.zst";
      hash = "sha256-5etn5fMMFNV+cL98oq2ICwmlLXXaHPXi3quyQYqEyNE=";
    };
    x86_64-linux = {
      url = "https://github.com/leanprover/lean4/releases/download/v4.32.0/lean-4.32.0-linux.tar.zst";
      hash = "sha256-/KhG81iHJKOK0Z7kApLGfLdDjXVVkDNy4zCO73lbpRY=";
    };
    x86_64-darwin = {
      url = "https://github.com/leanprover/lean4/releases/download/v4.32.0/lean-4.32.0-darwin.tar.zst";
      hash = "sha256-m0icke4QfFt2u4DHJXMfTTcNhQlMU7tFYVUX+xmnOmo=";
    };
    aarch64-darwin = {
      url = "https://github.com/leanprover/lean4/releases/download/v4.32.0/lean-4.32.0-darwin_aarch64.tar.zst";
      hash = "sha256-T6pHV/fKXn2ViKned5VQ+li98BSY7blm8VAp4uoRfk4=";
    };
  };
  inherit (import ./v4.19.0.nix) overlay;
  inherit (import ./v4.27.0.nix) buildLeanPackage;
  # Same bootstrap as v4.31.0, plus OpenSSL: Lean v4.32.0 requires OpenSSL >= 3
  # (`find_package(OpenSSL 3 REQUIRED)` in src/CMakeLists.txt) for the TLS
  # support added to the runtime. The wrapper re-declares the packages the
  # inner bootstrap needs because `callPackage` injects arguments based on the
  # formal parameter names, which a plain `args:` lambda does not expose.
  bootstrap = args @ {pkgs, ...}:
    (import ./v4.31.0.nix).bootstrap (
      {
        inherit
          (pkgs)
          lib
          cmake
          gmp
          libuv
          cadical
          git
          gnumake
          bash
          writeShellScriptBin
          runCommand
          symlinkJoin
          lndir
          perl
          pkg-config
          gnused
          darwin
          llvmPackages
          linkFarmFromDrvs
          ;
      }
      // args
      // {extraBuildInputs = [pkgs.openssl];}
    );
}
