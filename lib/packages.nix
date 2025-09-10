args @ {
  callPackage,
  lib,
  llvmPackages,
  stdenv,
  # If this is null, it uses the `buildLeanPackage.nix` in the provided `src`,
  # which only exists for versions 4.21 and below.
  buildLeanPackage ? null,
  # Either provide a built Lean ...
  lean-bin ? null,
  # Or provide sources and bootstrapping functions
  src ? null,
  bootstrap ? null,
}: let
  lean = callPackage bootstrap (args
    // {
      inherit (llvmPackages) stdenv;
      inherit src llvmPackages;
      buildLeanPackage = buildLeanPackageOverride;
    });

  stage1 = lib.defaultTo lean.stage1 lean-bin;

  makeOverridableLeanPackage = f: let
    newF = origArgs:
      f origArgs
      // {
        overrideArgs = newArgs: makeOverridableLeanPackage f (origArgs // newArgs);
      };
  in
    lib.setFunctionArgs newF (lib.functionArgs f)
    // {
      override = args: makeOverridableLeanPackage (f.override args);
    };

  buildLeanPackageOverride = makeOverridableLeanPackage (
    callPackage (
      lib.defaultTo (import "${src}/nix/buildLeanPackage.nix") buildLeanPackage
    )
    (
      args
      // {
        inherit stdenv;
        lean = stage1;
        inherit (stage1) leanc;
      }
    )
  );
in
  {buildLeanPackage = buildLeanPackageOverride;} // stage1
