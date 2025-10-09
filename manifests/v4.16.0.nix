{
  tag = "v4.16.0";
  rev = "128a1e6b0a82718382f9c39c79be44ff3284547c";

  toolchain = {
    aarch64-linux.hash = "sha256-DS+wSI6KXWedOD0chGr/Wm1XsnsOydXZsTliJvIxH4c=";
    x86_64-linux.hash = "sha256-zdMfEGR4P/8WO+U+KFciEC8Wdn5l5vt/fLHCMlFODDo=";
    x86_64-darwin.hash = "sha256-CMziTTWw5mbPvTgyYG7Du6eOB/q9NvFdLVda4ZKQ1tQ=";
    aarch64-darwin.hash = "sha256-V2LlrrK6IZCAZYkDZieYfI2R5JxUzGz5C5bt7GUngl0=";
  };

  inherit (import ./v4.14.0.nix) bootstrap;
}
