{
  inputs = {
    naersk.url = "github:nix-community/naersk/master";
    utils.url = "github:numtide/flake-utils/v1.0.0";
  };

  outputs = { self, nixpkgs, utils, naersk }:

    utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        naersk-lib = pkgs.callPackage naersk { };
        libllvm = pkgs.llvmPackages_13.libllvm;
        circom_deps = [ libllvm pkgs.libffi pkgs.libiconv pkgs.libxml2 pkgs.zlib ]
          ++ pkgs.lib.optional pkgs.stdenv.isDarwin [ pkgs.darwin.apple_sdk.frameworks.Security ];
      in rec {
        defaultPackage = with pkgs; naersk-lib.buildPackage {
           name = "circom";
           pname = "circom";
           src = ./.;

           buildInputs = circom_deps;
           checkInputs = [ lit libllvm ];

           doCheck = true;

           LLVM_SYS_130_PREFIX = "${libllvm.dev}";
         };

        devShell = with pkgs; mkShell {
          buildInputs = [ cargo rustc rustfmt pre-commit rustPackages.clippy lit ] ++ circom_deps;
          RUST_SRC_PATH = rustPlatform.rustLibSrc;
          LLVM_SYS_130_PREFIX = "${libllvm.dev}";
        };
      });
}
