# Lean 4 Nix

The unofficial Nix flake build for Lean 4.

## Usage

Execute
``` sh
nix flake new --template github:lenianiva/lean4-nix ./$PROJECT_NAME
```

## Flake outputs

Under `package.${system}`:
- `buildLeanPackage { name; roots; deps; src; }`: Given a directory `src`
  containing Lean files, builds a Lean package. `roots` indicates Lean files
  that are on the top of the import hierarchy. `deps` is a list of outputs of
  other `buildLeanPackage` calls.

  This function outputs `{ executable; sharedLib; ... }`.

- `lean`: The Lean executable
- `lean-all`: `lean`, `lake`, and the Lean library.
- `example`: Use `nix run .#example` to see an example of building a Lean program.



