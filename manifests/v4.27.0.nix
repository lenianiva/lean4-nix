{
  tag = "v4.27.0";
  rev = "db93fe1608548721853390a10cd40580fe7d22ae";
  toolchain = {
    aarch64-linux = {
      url = "https://github.com/leanprover/lean4/releases/download/v4.27.0/lean-4.27.0-linux_aarch64.tar.zst";
      hash = "sha256-slbuwna6qszD6z+mTXzP9k9xC3yqB08wW6leABOtMec=";
    };
    x86_64-linux = {
      url = "https://github.com/leanprover/lean4/releases/download/v4.27.0/lean-4.27.0-linux.tar.zst";
      hash = "sha256-BW4tyFZPwGSoAeafPrGMBEubVGvIsOWiwAJH+KHLjOY=";
    };
    x86_64-darwin = {
      url = "https://github.com/leanprover/lean4/releases/download/v4.27.0/lean-4.27.0-darwin.tar.zst";
      hash = "sha256-5MpUHYaIHDVJfLbmwaITWPA6Syz7Lo1OFOWNwqCoBa4=";
    };
    aarch64-darwin = {
      url = "https://github.com/leanprover/lean4/releases/download/v4.27.0/lean-4.27.0-darwin_aarch64.tar.zst";
      hash = "sha256-AefZEwRkvH2Ee67OB9+yxPSN0C5xtLmnfUhJFOpZTvs=";
    };
  };
  inherit (import ./v4.23.0.nix) bootstrap buildLeanPackage;
}
