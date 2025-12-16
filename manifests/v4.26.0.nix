{
  tag = "v4.26.0";
  rev = "d8204c9fd894f91bbb2cdfec5912ec8196fd8562";
  toolchain = {
    aarch64-linux = {
      url = "https://github.com/leanprover/lean4/releases/download/v4.26.0/lean-4.26.0-linux_aarch64.tar.zst";
      hash = "sha256-vzHFNnOjLOrI07uQNzYXQ5sj7IChbtpwyyQ9LchAh8E=";
    };
    x86_64-linux = {
      url = "https://github.com/leanprover/lean4/releases/download/v4.26.0/lean-4.26.0-linux.tar.zst";
      hash = "sha256-hzwlKxxrE5LlcgrY1aE3qrvnLJ+WqTD9taHdHdxdpFQ=";
    };
    x86_64-darwin = {
      url = "https://github.com/leanprover/lean4/releases/download/v4.26.0/lean-4.26.0-darwin.tar.zst";
      hash = "sha256-N5HhO7Y8+kO4QF60GMd7FisPx0+2Dv5rW/151I+4nO0=";
    };
    aarch64-darwin = {
      url = "https://github.com/leanprover/lean4/releases/download/v4.26.0/lean-4.26.0-darwin_aarch64.tar.zst";
      hash = "sha256-nsmYcAg2SOMRZJ5K3EWFRWvl0JXN5kwFwYHTV05BT74=";
    };
  };
  inherit (import ./v4.23.0.nix) bootstrap buildLeanPackage;
}
