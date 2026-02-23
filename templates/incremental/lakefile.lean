import Lake
open Lake DSL

require batteries from git
  "https://github.com/leanprover-community/batteries" @ "v4.27.0"

package Incremental

@[default_target]
lean_lib Incremental

@[test_driver]
lean_exe IncrementalTest
