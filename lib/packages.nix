args @{ bootstrap
, callPackage
, lib
, llvmPackages
, src
}:

let
  lean = callPackage bootstrap (args // {
    inherit (llvmPackages) stdenv;
    inherit src buildLeanPackage llvmPackages;
  });

  makeOverridableLeanPackage = f:
    let
      newF = origArgs: f origArgs // {
        overrideArgs = newArgs: makeOverridableLeanPackage f (origArgs // newArgs);
      };
    in
    lib.setFunctionArgs newF (lib.functionArgs f) // {
      override = args: makeOverridableLeanPackage (f.override args);
    };

  buildLeanPackage = makeOverridableLeanPackage (callPackage (import "${src}/nix/buildLeanPackage.nix") (args // {
    inherit (lean) stdenv;
    lean = lean.stage1;
    inherit (lean.stage1) leanc;
  }));
in
{ inherit buildLeanPackage; } // lean.stage1
