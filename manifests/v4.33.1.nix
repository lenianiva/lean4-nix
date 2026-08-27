{
  tag = "v4.33.1";
  rev = "819816b2e0a3bf405af45ae5c7af2491d8f5bee6";
  toolchain = {
    aarch64-linux = {
      url = "https://github.com/leanprover/lean4/releases/download/v4.33.1/lean-4.33.1-linux_aarch64.tar.zst";
      hash = "sha256-9zU6iyqHQchFWFI+RQVW+aHEXjyvz1Q5nOaMaiTFXwc=";
    };
    x86_64-linux = {
      url = "https://github.com/leanprover/lean4/releases/download/v4.33.1/lean-4.33.1-linux.tar.zst";
      hash = "sha256-iQr9GFNw+FZmAluIORSrT0szkTb4yWFntpz7Yq7K8jU=";
    };
    x86_64-darwin = {
      url = "https://github.com/leanprover/lean4/releases/download/v4.33.1/lean-4.33.1-darwin.tar.zst";
      hash = "sha256-k8R1wWADYN81Rxv27Rx/4RjX+0K+aRXq1nck961Y368=";
    };
    aarch64-darwin = {
      url = "https://github.com/leanprover/lean4/releases/download/v4.33.1/lean-4.33.1-darwin_aarch64.tar.zst";
      hash = "sha256-iMRarZhbXSqNkl/hC9Epa9NfZvQISAqxgtP6zM0GWp0=";
    };
  };
  inherit (import ./v4.19.0.nix) overlay;
  inherit (import ./v4.27.0.nix) buildLeanPackage;
  inherit (import ./v4.32.0.nix) bootstrap;
}
