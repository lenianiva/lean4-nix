{
  tag = "v4.25.2";
  rev = "b86e2e5824bcdbfa0e8d02dd97b4c48792a385d1";
  toolchain = {
    aarch64-linux.hash = "sha256-jbxyTg/5FcgmPBdOtoNdVOUyG0ukVDN7AmihIINuBd4=";
    x86_64-linux.hash = "sha256-QdX5ANqlFnwIvWGF5taa+DlD7TWDot7ETyv+dEG1bNs=";
    x86_64-darwin.hash = "sha256-B/JaT9Kz19kSVtM60+tcf+pyBMLLyjHAjjzwGC59cEo=";
    aarch64-darwin.hash = "sha256-+fUNe/xCYCl4ipRisMAa7bRiwl9iP6qPy+6e8SgacPs=";
  };
  inherit (import ./v4.23.0.nix) bootstrap buildLeanPackage;
}
