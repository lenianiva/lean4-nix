{
  tag = "v4.29.0";
  rev = "98dc76e3c0a9b856c9b98726b713fb04fab16740";
  toolchain = {
    aarch64-linux = {
      url = "https://github.com/leanprover/lean4/releases/download/v4.29.0/lean-4.29.0-linux_aarch64.tar.zst";
      hash = "sha256-N5BHyBNnqfBYoPNrNXQHO0wQ8MoSbdAj6YUFNjDwC3c=";
    };
    x86_64-linux = {
      url = "https://github.com/leanprover/lean4/releases/download/v4.29.0/lean-4.29.0-linux.tar.zst";
      hash = "sha256-CJ9+UT7T6UNtGR9JhjMMC1OAnIa1mX9et/JVUMN0+kg=";
    };
    x86_64-darwin = {
      url = "https://github.com/leanprover/lean4/releases/download/v4.29.0/lean-4.29.0-darwin.tar.zst";
      hash = "sha256-/6y9ZMYLzJBY42kL4/93fZMloIx5XLuyduUPq10GYRo=";
    };
    aarch64-darwin = {
      url = "https://github.com/leanprover/lean4/releases/download/v4.29.0/lean-4.29.0-darwin_aarch64.tar.zst";
      hash = "sha256-dDCbjyMS8OhgjgKB/UewjSE7zVPzwgmfzRDOOhpG8Mg=";
    };
  };
  inherit (import ./v4.23.0.nix) bootstrap;
  inherit (import ./v4.27.0.nix) buildLeanPackage;
}
