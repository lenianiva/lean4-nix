import Lake
open Lake DSL

package template

lean_lib Template {
  roots := #[`Main]
  defaultFacets := #[LeanLib.sharedFacet]
}

@[default_target]
lean_exe template {
  root := `Main
}
