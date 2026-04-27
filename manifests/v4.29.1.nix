{
  tag = "v4.29.1";
  rev = "f72c35b3f637c8c6571d353742168ab66cc22c00";
  overlay = final: prev: {
    cadical = prev.cadical.overrideAttrs {
      version = "2.1.2";
      src = prev.fetchFromGitHub {
        owner = "arminbiere";
        repo = "cadical";
        rev = "rel-2.1.2";
        hash = "sha256-fhvQd/f8eaw7OA2/XoOTVOnQxSSxUvugu6VWo2nmpQ0=";
      };
    };
  };
  toolchain = {
    aarch64-linux = {
      url = "https://github.com/leanprover/lean4/releases/download/v4.29.1/lean-4.29.1-linux_aarch64.tar.zst";
      hash = "sha256-HM37f5JJAfS3OktOsWnls9x09oNlIbR+cz6iXyq/wNw=";
    };
    x86_64-linux = {
      url = "https://github.com/leanprover/lean4/releases/download/v4.29.1/lean-4.29.1-linux.tar.zst";
      hash = "sha256-vwYtKVVtZVaF+yh1Y8JJrWqP3jQ1LBi14yVopZXBrsE=";
    };
    x86_64-darwin = {
      url = "https://github.com/leanprover/lean4/releases/download/v4.29.1/lean-4.29.1-darwin.tar.zst";
      hash = "sha256-NYWrNNIMU8+RUWmqXA0u+9mZOni53AhRZkFRDu8I+rA=";
    };
    aarch64-darwin = {
      url = "https://github.com/leanprover/lean4/releases/download/v4.29.1/lean-4.29.1-darwin_aarch64.tar.zst";
      hash = "sha256-c7zLOSyn2Ks9YqHjKLt9BXgV8Ijb2/tldPGUrlBXl68=";
    };
  };
  inherit (import ./v4.29.0.nix) bootstrap;
  inherit (import ./v4.27.0.nix) buildLeanPackage;
}
