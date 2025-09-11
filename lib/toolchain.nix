{
  config,
  lib,
  pkgs,
  ...
}: {
  toolchain-fetch = pkgs.writeShellApplication {
    name = "toolchain-fetch";
    runtimeInputs = with pkgs; [git wget coreutils nix];
    text = ./toolchain-fetch.sh;
  };
}
