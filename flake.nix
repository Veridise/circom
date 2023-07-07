{
  inputs = {
    naersk.url = "github:nix-community/naersk/master";
    utils.url = "github:numtide/flake-utils/v1.0.0";
  };

  outputs = { self, nixpkgs, utils, naersk }:

    utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        llvmPackages_13 = pkgs.llvmPackages_13;
        naersk-lib = pkgs.callPackage naersk { };
      in
      {
        defaultPackage = naersk-lib.buildPackage {
           pname = "circom";
           src = ./.;

           buildInputs = [ llvmPackages_13.libllvm pkgs.libffi pkgs.libiconv pkgs.libxml2 pkgs.zlib ]
                ++ pkgs.lib.optional pkgs.stdenv.isDarwin [ pkgs.darwin.apple_sdk.frameworks.Security ];
           LLVM_SYS_130_PREFIX = "${llvmPackages_13.libllvm.dev}";
         };
        devShell = with pkgs; mkShell {
          buildInputs = [ cargo rustc rustfmt pre-commit rustPackages.clippy ];
          RUST_SRC_PATH = rustPlatform.rustLibSrc;
        };
      });
}
