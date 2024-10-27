rec {
  minimal = {
    path = ./minimal;
    description = "Minimal Executable";
  };
  dependency = {
    path = ./dependency;
    description = "With Dependency";
  };
  default = minimal;
}
