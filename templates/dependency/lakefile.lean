import Lake
open Lake DSL

require aesop from git
  "https://github.com/leanprover-community/aesop.git" @ "v4.22.0-rc4"

package Example

@[default_target]
lean_lib Example
