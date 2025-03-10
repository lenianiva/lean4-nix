{
  lean,
  lib,
  ...
}:
(lean.buildLeanPackage
  {
    name = "Example";
    roots = ["Main"];
    src = lib.cleanSource ./.;
  })
.executable
