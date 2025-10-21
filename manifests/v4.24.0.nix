{
  tag = "v4.24.0";
  rev = "797c613eb9b6d4ec95db23e3e00af9ac6657f24b";
  toolchain = {
    aarch64-linux.hash = "sha256-I3+O9D+0DRZoGHH7BLLFbwI6/AKlo4d4MdNd1JOCPCM=";
    x86_64-linux.hash = "sha256-sU9eUVkhndGhlWw7gGgTMZ9elMzVvf1W9UUgYJpbtew=";
    x86_64-darwin.hash = "sha256-pe8PsOFGReqg5gvGujmgfn3u7sc9yTznGVuDfrneLJ8=";
    aarch64-darwin.hash = "sha256-F+5VRwLBmfwD83scNwgkVnHJP12TLc/1WgP6bNteWt8=";
  };
  inherit (import ./v4.23.0.nix) bootstrap buildLeanPackage;
}
