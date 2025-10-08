{
  tag = "v4.18.0";
  rev = "11ccbced796476be020459a83c599b301a765d3e";
  toolchain = {
    aarch64-linux.hash = "sha256-db4ei5CdwZc0GqEwo8GHibPE+Eot1ZNXrKCMx3lqtGk=";
    x86_64-linux.hash = "sha256-Vncl+DEzt0Sdv8brh7vDHxxN+NA1aH0X8H5GzniieYA=";
    x86_64-darwin.hash = "sha256-Bz/1wstpBMWQpDirkAYEdJyYXIbm5ZGJ6A0C5oONAAQ=";
    aarch64-darwin.hash = "sha256-agMaVFparEJnJtnyqpfr5LyQrimDJsIO8dG8gTop8YQ=";
  };

  inherit (import ./v4.17.0.nix) bootstrap;
}
