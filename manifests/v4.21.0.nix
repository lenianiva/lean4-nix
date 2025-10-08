{
  tag = "v4.21.0";
  rev = "6741444a63eec253a7eae7a83f1beb3de015023d";
  toolchain = {
    aarch64-linux.hash = "sha256-NDLqaxMzqljqD2ST/PxeiPao4TJFjhQ9/pAStcQvAwE=";
    x86_64-linux.hash = "sha256-RVxt8J1b1U0qUbE3k5xH4t2oFtUSrHicSzZCyb+Yveg=";
    x86_64-darwin.hash = "sha256-28ikkTuJkmtG8pmKPytjf7ilpvdRGN5/zYTMf/J0vFI=";
    aarch64-darwin.hash = "sha256-49fTHdD9t7/RpLlT4Tsyzv6E3wTflhBv+Krad1OG2os=";
  };
  inherit (import ./v4.19.0.nix) bootstrap;
}
