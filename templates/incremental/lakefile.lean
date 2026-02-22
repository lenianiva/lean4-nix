import Lake
open Lake DSL

require Example from git "https://github.com/lenianiva/lean4-nix" @ "main" / "templates/dependency"

package Incremental

@[default_target]
lean_lib Incremental

@[test_driver]
lean_exe IncrementalTest
