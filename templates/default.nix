rec {
  minimal = {
    path = ./minimal;
    description = "Minimal Executable";
  };
  dependency = {
    path = ./dependency;
    description = "With Dependency";
  };
  incremental = {
    path = ./incremental;
    description = "With Incremental builds";
  };
  lean-import = {
    path = ./lean-import;
    description = "Import library with lakefile.lean";
  };
  default = minimal;
}
