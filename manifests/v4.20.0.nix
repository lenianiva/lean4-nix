{
  tag = "v4.20.0";
  rev = "77cfc4d1a4f6ef6651792b781eaa6676b4f3f060";
  toolchain = {
    aarch64-linux.hash = "sha256-IixYUFQHDTsm9cgY/5t21BW2oCxiA0ulkdx4DxJ98o0=";
    x86_64-linux.hash = "sha256-87BYQw+H3ZVpx+vSafCvG+ewELdUhJtUPubPnMwI1PA=";
    x86_64-darwin.hash = "sha256-IWE6B01SziANkNkpzX1ILu2QvGsuqDaclyCW7y9P9Ag=";
    aarch64-darwin.hash = "sha256-G9am9JtTDmKPGP5FYmbC77NMRmmRXSkbfvPcxO4vTyA=";
  };
  inherit (import ./v4.19.0.nix) bootstrap;
}
