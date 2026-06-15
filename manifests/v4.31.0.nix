{
  tag = "v4.31.0";
  rev = "68218e876d2a38b1985b8590fff244a83c321783";
  toolchain = {
    aarch64-linux = {
      url = "https://github.com/leanprover/lean4/releases/download/v4.31.0/lean-4.31.0-linux_aarch64.tar.zst";
      hash = "sha256-sb8dPFhrds9KhiEqWV2Lnt2Z9DikHM6F1XgPqTR8gRs=";
    };
    x86_64-linux = {
      url = "https://github.com/leanprover/lean4/releases/download/v4.31.0/lean-4.31.0-linux.tar.zst";
      hash = "sha256-B6YzzI2RUcvAiCXqTN2lDUsCosnLhSwBMbEwRvScrX8=";
    };
    x86_64-darwin = {
      url = "https://github.com/leanprover/lean4/releases/download/v4.31.0/lean-4.31.0-darwin.tar.zst";
      hash = "sha256-bax6j51tC8M5tOqTdsBqiPP9Gn9GK+s8fe2fvJNPP7U=";
    };
    aarch64-darwin = {
      url = "https://github.com/leanprover/lean4/releases/download/v4.31.0/lean-4.31.0-darwin_aarch64.tar.zst";
      hash = "sha256-JkEFUAyKvfN7aP/gM5Cng+0lmAeAciJpjajdktbOCic=";
    };
  };
  inherit (import ./v4.19.0.nix) overlay;
  inherit (import ./v4.30.0.nix) bootstrap;
  inherit (import ./v4.27.0.nix) buildLeanPackage;
}
