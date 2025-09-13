{
  config,
  lib,
  pkgs,
  ...
}: {
  toolchain-fetch = pkgs.writeShellApplication {
    name = "toolchain-fetch";
    runtimeInputs = with pkgs; [jq git wget coreutils nix];
    text = ''exec ${./toolchain-fetch.sh} "$@"'';
  };
}
