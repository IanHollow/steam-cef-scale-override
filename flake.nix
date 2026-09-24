{
  description = "Standalone source and Nix package for steam-cef-scale-override";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { nixpkgs, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
      package = pkgs.callPackage ./package.nix { };
    in
    {
      packages.${system}.default = package;
      checks.${system}.package = package;
      devShells.${system}.default = pkgs.mkShell {
        packages = with pkgs; [
          binutils
          clang-tools
          meson
          ninja
          nixfmt
          shellcheck
          shfmt
        ];
      };
    };
}
