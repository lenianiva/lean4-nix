{
  tag = "v4.28.0";
  rev = "7e01a1bf5c70fc6167d49c345d3bf80596e9a79b";
  toolchain = {
    aarch64-linux = {
      url = "https://github.com/leanprover/lean4/releases/download/v4.28.0/lean-4.28.0-linux_aarch64.tar.zst";
      hash = "sha256-yGWAEmHHR9TxXQi+ypq8IKypB5BKu7KE3iWjf0tFWLw=";
    };
    x86_64-linux = {
      url = "https://github.com/leanprover/lean4/releases/download/v4.28.0/lean-4.28.0-linux.tar.zst";
      hash = "sha256-zrOj+ET3rr9jJF4rUcKNWw7TiULBn5PPP+vVIDAhYL0=";
    };
    x86_64-darwin = {
      url = "https://github.com/leanprover/lean4/releases/download/v4.28.0/lean-4.28.0-darwin.tar.zst";
      hash = "sha256-TJfaEKkm2Qat8z/JmKJUakED6gzfmVzs78G6ox/twAg=";
    };
    aarch64-darwin = {
      url = "https://github.com/leanprover/lean4/releases/download/v4.28.0/lean-4.28.0-darwin_aarch64.tar.zst";
      hash = "sha256-YZQvnRkH25GAIBVKUXyH+2SEHkjOuwAy/AkJ340YmgU=";
    };
  };
  inherit (import ./v4.23.0.nix) bootstrap;
  inherit (import ./v4.27.0.nix) buildLeanPackage;
}
