{
  tag = "v4.25.0";
  rev = "cdd38ac5115bdeec5f609e9126cce00f51ae88b3";
  toolchain = {
    aarch64-linux = {
      url = "https://github.com/leanprover/lean4/releases/download/v4.25.0/lean-4.25.0-linux_aarch64.tar.zst";
      hash = "sha256-2j6slOyrgHejyo18TpVx24ijA7yFkYzhRfH2Y6JRnus=";
    };
    x86_64-linux = {
      url = "https://github.com/leanprover/lean4/releases/download/v4.25.0/lean-4.25.0-linux.tar.zst";
      hash = "sha256-l77nvaZ2ylT0sc6+MjJCoIMj11E0/s0boxzuTbZqu4o=";
    };
    x86_64-darwin = {
      url = "https://github.com/leanprover/lean4/releases/download/v4.25.0/lean-4.25.0-darwin.tar.zst";
      hash = "sha256-JwZmMTllGvCSgEdlDlm4lMMhQm3AwQg/08lqsDBw/sY=";
    };
    aarch64-darwin = {
      url = "https://github.com/leanprover/lean4/releases/download/v4.25.0/lean-4.25.0-darwin_aarch64.tar.zst";
      hash = "sha256-uD4JXe+WtM+BTI5OIiK789ZPVfRIRV4THgZ/H+1JHjA=";
    };
  };
  inherit (import ./v4.23.0.nix) bootstrap buildLeanPackage;
}
