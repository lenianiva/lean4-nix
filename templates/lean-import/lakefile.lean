import Lake
open Lake DSL

require Example from git "https://github.com/lenianiva/lean4-nix" @ "main" / "templates/incremental"

package LeanImport

@[default_target]
lean_exe leanImport where
  root := `Main
