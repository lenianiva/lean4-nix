# Lean 4 Nix

The unofficial Nix flake build for Lean 4.

## Example

The default template is a good starting point

``` sh
nix flake new --template#minimal github:lenianiva/lean4-nix
```

The `.#dependency` template shows an example of using `lake-manifest.json` to
fetch dependencies automatically.

``` sh
nix flake new --template#dependency github:lenianiva/lean4-nix
```

## Flake outputs

### Overlay

The user must decide on a Lean version to use as overlay. The minimal supported
version is `v4.12.0`, since it is the version when Lean's official Nix flake was
deprecated. There are a couple of ways to get an overlay. Each corresponds to a
flake output:

- `readSrc`: Builds Lean from a source folder.
- `readFromGit`: Given parameters to `builtins.fetchGit`, download a git repository
- `readRev`: Reads a revision from the official Lean 4 repository
- `readToolchainFile`: Reads the toolchain from a file. Due to Nix's pure
  evaluation principle, this only supports `leanprover/lean4:{tag}` based
  `lean-toolchain` files. For any other toolchains, use `readRev` or `readFromGit`.
- `tags.{tag}`: Lean4 tags. See the available tags in `manifests/`

Then apply the overlay on `pkgs`:
```nix
pkgs = import nixpkgs {
  inherit system;
  overlays = [ lean4-nix.tags."v4.12.0" ];
};
```
and `pkgs.lean` will be replaced by the chosen overlay.

### `pkgs.lean`

This attribute set has properties

- `lean`: The Lean executable
- `lean-all`: `lean`, `lake`, and the Lean library.
- `example`: Use `nix run .#example` to see an example of building a Lean program.
- `Init`, `Std`, `Lean`: Lean built-in libraries provided in the same format as `buildLeanPackage`

There are two functions which can be used to build Lean packages:

- `buildLeanPackage { name; roots; deps; src; }`: Given a directory `src`
  containing Lean files, builds a Lean package. `roots` indicates Lean files
  that are on the top of the import hierarchy. `deps` is a list of outputs of
  other `buildLeanPackage` calls. This is the more manual version.

  This function outputs `{ executable; sharedLib; ... }`.
- `mkPackage { src; roots; }`: Automatically reads the `lake-manifest.json` file
  from a directory and builds all the dependencies.


## Troubleshooting

### attribute '"{Lean,Init}.*"' is missing

If you see this error, add these packages to `deps` in either `buildLeanPackage` or `mkPackage`.
``` nix
{
  deps = with pkgs.lean; [ Init Std Lean ];
}
```
in the call to `buildLeanPackage`


## Development

Use `nix flake check` to check the template builds.

Update the template `lean-toolchain` files when new Lean versions come out
