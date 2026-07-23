{
  description = "IceDOS config casing migration tool";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { nixpkgs, ... }:
    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          script = pkgs.writeShellApplication {
            name = "icedos-migrate-casing";
            runtimeInputs = [ pkgs.python3 ];
            text = ''exec python3 ${./migrate-casing.py} "$@"'';
          };
        in
        { default = script; }
      );

      devShells = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.mkShell { packages = [ pkgs.python3 ]; };
        }
      );
    };
}
