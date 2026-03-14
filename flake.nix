{
  description = "A Nix-flake-based Rust development environment";
  inputs = {
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1";
    fenix = {
      url = "https://flakehub.com/f/nix-community/fenix/0.1";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs =
    { self, ... }@inputs:
    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forEachSupportedSystem =
        f:
        inputs.nixpkgs.lib.genAttrs supportedSystems (
          system:
          f {
            pkgs = import inputs.nixpkgs {
              inherit system;
              overlays = [ inputs.self.overlays.default ];
            };
          }
        );
    in
    {
      overlays.default = final: prev: {
        rustToolchain =
          with inputs.fenix.packages.${prev.stdenv.hostPlatform.system};
          combine (
            with stable; [
              clippy
              rustc
              cargo
              rustfmt
              rust-src
            ]
          );
      };
      devShells = forEachSupportedSystem (
        { pkgs }:
        {
          default = pkgs.mkShell {
            packages = with pkgs; [
              # Rust toolchain
              rustToolchain
              rust-analyzer

              # Build essentials
              openssl
              pkg-config

              # Cargo tools
              cargo-binstall
              cargo-deny
              cargo-edit
              cargo-leptos
              cargo-tauri
              cargo-watch
              sqlx-cli

              # Bindgen & WASM
              rust-bindgen
              wasm-bindgen-cli

              # Formatting / linting
              leptosfmt
              typos

              # Utilities
              just
              tokei
            ];

            env = {
              RUST_SRC_PATH = "${pkgs.rustToolchain}/lib/rustlib/src/rust/library";
            };

            # ui-cli (Rust/UI) — not yet in nixpkgs, installed via cargo-binstall
            shellHook = ''
              if ! command -v ui &> /dev/null; then
                echo "Installing rust-ui CLI via cargo-binstall..."
                cargo binstall rust-ui-cli -y
              fi
            '';
          };
        }
      );
    };
}
