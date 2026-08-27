{
  tag = "v4.33.0";
  rev = "d8b18978322de05a8f3dba51ef03cf5461676c17";
  toolchain = {
    aarch64-linux = {
      url = "https://github.com/leanprover/lean4/releases/download/v4.33.0/lean-4.33.0-linux_aarch64.tar.zst";
      hash = "sha256-+WGkF8uhC26gqdE2cS1ZUoE4F//WaABB8JojNSb4A6k=";
    };
    x86_64-linux = {
      url = "https://github.com/leanprover/lean4/releases/download/v4.33.0/lean-4.33.0-linux.tar.zst";
      hash = "sha256-Sz+wPCmh4KJT+x0R+brjcl8ZoNxvwJs+oW0snfM0niw=";
    };
    x86_64-darwin = {
      url = "https://github.com/leanprover/lean4/releases/download/v4.33.0/lean-4.33.0-darwin.tar.zst";
      hash = "sha256-GMSt/S5FOMNmj34HDojHohV23un730beffLvFsl//vM=";
    };
    aarch64-darwin = {
      url = "https://github.com/leanprover/lean4/releases/download/v4.33.0/lean-4.33.0-darwin_aarch64.tar.zst";
      hash = "sha256-21J0tmm+JwrwSLXk8eDOVx32dQ5BGVaz4eb8wgEkEMI=";
    };
  };
  inherit (import ./v4.19.0.nix) overlay;
  inherit (import ./v4.27.0.nix) buildLeanPackage;
  inherit (import ./v4.32.0.nix) bootstrap;
}
