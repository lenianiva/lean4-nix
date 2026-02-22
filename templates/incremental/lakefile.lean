import Lake
open Lake DSL

require aesop from git
  "https://github.com/leanprover-community/aesop.git" @ "v4.28.0"
require Example from git "https://github.com/lenianiva/lean4-nix" @ "main" / "templates/dependency"

package Incremental

@[default_target]
lean_lib Incremental

@[test_driver]
lean_exe IncrementalTest
